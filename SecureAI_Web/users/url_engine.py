"""
SecureAI URL Threat Intelligence & Redirect Analysis Engine
============================================================
A hardened, SSRF-defended, anti-rebinding URL redirect resolution and threat
intelligence engine for SMS spam detection, email phishing analysis, and QR auditing.

Security Guarantees:
1. Strict SSRF Protection: Comprehensive IPv4 and IPv6 prohibited subnet validation
   (loopback, private RFC 1918, link-local / cloud metadata 169.254.169.254, multicast,
   IPv4-mapped IPv6, ULA).
2. Anti-DNS Rebinding (TOCTOU): Bounded DNS resolution pins the validated IP; a custom
   transport adapter (PinnedHTTPAdapter) dials the pinned IP directly while preserving
   TLS SNI and certificate hostname matching against the original domain.
3. Process-Isolated DNS Worker with Global Concurrency Control: DNS resolution executes in an
   isolated worker using an explicit spawn multiprocessing context (mp.get_context('spawn'))
   with enforceable termination (SIGTERM/kill) upon deadline expiration.
   A cross-process file-descriptor lock manager enforces an application-wide concurrency ceiling
   (max 4 DNS workers server-wide across all Gunicorn workers). Unbounded fallback is disallowed:
   if process isolation or lock directories fail, the engine fails closed with UNVERIFIED. An in-memory
   60-second LRU cache avoids redundant lookups.
4. Bounded Monotonic Timeouts & Scheduling Semantics: Monotonic wall-clock budgets span extraction,
   DNS lookups, TCP connects, TLS handshakes, redirect traversal, and threat intelligence.
   Dynamic per-read socket tuning bounds blocking socket operations against the remaining deadline.
   The <= 50ms tolerance is an empirically observed scheduling tolerance under test conditions on general-purpose
   OS schedulers, not a hard mathematical or real-time OS guaranteed upper bound.
5. Content & Port Policy: Destination ports outside [80, 443, 8080, 8443] and embedded
   credentials (user:pass@) are intercepted pre-flight. Explicit non-HTTP schemes (file:,
   ftp:, javascript:) are rejected as BLOCKED_POLICY.
6. Slow-Trickle & Slowloris Defense: Response-header reading (Slowloris) and body streaming are
   bounded by dynamic per-read socket timeout adjustments and deadline checks inside
   DeadlineSocketWrapper, ensuring socket reads terminate promptly when the budget expires.
7. Decoupled Forensics: User-generated content platforms (e.g. forms.gle, S3) are categorized
   as 'Unverified (User-Hosted Content)' at the URL level without conflating infrastructure
   with confirmed malware.
8. Explicit Verdict Distinction: Differentiates 'Safe (Threat Intel Verified)' from
   'Safe (Heuristic Verified)'. No single signal can unilaterally mark a URL safe.
   HTTP 4xx and 5xx responses strictly produce UNVERIFIED, never Safe.
"""

from __future__ import annotations

import collections
from dataclasses import dataclass, field
import ipaddress
import logging
import multiprocessing as mp
import os
import queue
import re
import select
import socket
import ssl
import stat
import sys
import tempfile
import threading
import time
from typing import Any, Dict, List, Optional, Set, Tuple
from urllib.parse import urljoin, urlparse

import requests
from requests.adapters import HTTPAdapter
import urllib3.connection
from urllib3.connectionpool import HTTPConnectionPool, HTTPSConnectionPool
from urllib3.exceptions import SSLError as Urllib3SSLError

logger = logging.getLogger(__name__)

# ==============================================================================
# 1. SECURITY POLICY CONSTANTS & TAXONOMY
# ==============================================================================

# IPv4 and IPv6 subnets prohibited from backend resolution
PROHIBITED_NETWORKS: Tuple[ipaddress.IPv4Network | ipaddress.IPv6Network, ...] = (
    # IPv4 Private / Loopback / Cloud Metadata
    ipaddress.ip_network('0.0.0.0/8'),          # Current network (RFC 1122)
    ipaddress.ip_network('10.0.0.0/8'),         # RFC 1918 Private Class A
    ipaddress.ip_network('100.64.0.0/10'),      # Carrier-Grade NAT (RFC 6598)
    ipaddress.ip_network('127.0.0.0/8'),        # Loopback / Localhost (RFC 1122)
    ipaddress.ip_network('169.254.0.0/16'),     # Link-Local / Cloud Metadata (AWS/GCP/Azure)
    ipaddress.ip_network('172.16.0.0/12'),      # RFC 1918 Private Class B
    ipaddress.ip_network('192.168.0.0/16'),     # RFC 1918 Private Class C
    ipaddress.ip_network('198.18.0.0/15'),      # Benchmark testing (RFC 2544)
    ipaddress.ip_network('224.0.0.0/4'),        # Multicast (RFC 5771)
    ipaddress.ip_network('240.0.0.0/4'),        # Reserved for future use (RFC 1112)
    ipaddress.ip_network('255.255.255.255/32'), # Broadcast
    # IPv6 Prohibitions
    ipaddress.ip_network('::1/128'),            # Loopback (RFC 4291)
    ipaddress.ip_network('::/128'),             # Unspecified address (RFC 4291)
    ipaddress.ip_network('::ffff:0:0/96'),      # IPv4-mapped IPv6 (RFC 4291)
    ipaddress.ip_network('64:ff9b::/96'),       # IPv4/IPv6 translation (RFC 6052)
    ipaddress.ip_network('100::/64'),           # Discard prefix (RFC 6666)
    ipaddress.ip_network('2001:db8::/32'),      # Documentation (RFC 3849)
    ipaddress.ip_network('fc00::/7'),           # Unique Local Address ULA (RFC 4193)
    ipaddress.ip_network('fe80::/10'),          # Link-Local Unicast (RFC 4291)
)

# Destination ports permitted by policy (Note: Permitted ports do NOT establish trust)
PERMITTED_PORTS: Set[int] = {80, 443, 8080, 8443}

# Known URL shortener domains
KNOWN_SHORTENERS: Set[str] = {
    'bit.ly', 'tinyurl.com', 't.co', 'goo.gl', 'ow.ly', 'is.gd',
    'buff.ly', 'adf.ly', 'bit.do', 'shorturl.at', 'rb.gy', 'cutt.ly',
    'rebrand.ly', 'v.gd', 'bl.ink', 'cli.re', 'snip.ly', 'clck.ru'
}

# User-generated content / cloud hosting platforms (legitimate domains, but hosted content unverified)
UGC_DOMAINS: Set[str] = {
    'forms.gle', 'docs.google.com', 'drive.google.com', 'sites.google.com',
    'github.com', 'raw.githubusercontent.com', 'gist.github.com', 'gitlab.com',
    'blob.core.windows.net', 's3.amazonaws.com', 'storage.googleapis.com',
    'firebaseapp.com', 'web.app', 'pages.dev', 'vercel.app', 'notion.so',
    'dropbox.com', 'onedrive.live.com', 'sharepoint.com'
}

# High-risk top-level domains frequently abused by phishing kits
SUSPICIOUS_TLDS: Set[str] = {
    '.xyz', '.top', '.work', '.click', '.buzz', '.tokyo', '.cn',
    '.ru', '.su', '.fit', '.gq', '.ml', '.cf', '.ga', '.tk', '.rest'
}

# High-risk keywords commonly paired with brand spoofing
HIGH_RISK_KEYWORDS: Set[str] = {
    'login', 'verify', 'account', 'banking', 'secure', 'update',
    'signin', 'password', 'credential', 'wallet', 'confirm', 'suspend'
}

# Recognized high-target consumer brands
POPULAR_BRANDS: Set[str] = {
    'paypal', 'google', 'apple', 'microsoft', 'amazon', 'netflix',
    'facebook', 'instagram', 'whatsapp', 'chase', 'wellsfargo', 'bankofamerica'
}

# Stream read limits
MAX_BODY_STREAM_BYTES: int = 65536  # 64 KB hard cap
STREAM_CHUNK_SIZE: int = 8192       # 8 KB per chunk
MAX_REDIRECT_HOPS: int = 5
MAX_SCANNED_URLS: int = 10
OVERALL_BUDGET_SECONDS: float = 5.0

# In-memory DNS cache: domain -> (list_of_ips, expire_timestamp)
_DNS_CACHE: Dict[str, Tuple[List[str], float]] = {}
_DNS_CACHE_TTL_SECONDS: float = 60.0
_DNS_CACHE_MAX_ENTRIES: int = 256

# Maximum global concurrent DNS processes across all Gunicorn workers
MAX_GLOBAL_DNS_WORKERS: int = 4


# ==============================================================================
# 2. CROSS-PROCESS CONCURRENCY LOCK (GUNICORN-WIDE)
# ==============================================================================

class GlobalCrossProcessSlotLock:
    """
    Guarantees an application-wide concurrency limit across multiple Gunicorn
    worker processes using OS kernel-managed file descriptor locks.
    Locks are automatically freed by the OS kernel if a process crashes or exits,
    completely preventing permanent lock leaks.
    On Linux, uses directory file descriptors (dir_fd) with O_DIRECTORY and
    descriptor-relative openat(2) to eliminate directory-level TOCTOU symlink races.
    """
    def __init__(self, max_slots: int = MAX_GLOBAL_DNS_WORKERS, slot_dir: Optional[str] = None):
        self.max_slots = max_slots
        self.last_error: Optional[str] = None
        self._dir_fd: Optional[int] = None
        self._current_slot_fd: Optional[int] = None
        self._current_slot_file: Optional[str] = None
        self._retain_locked: bool = False
        self._thread_lock = threading.Lock()

        if slot_dir is not None:
            valid, dir_fd = self._validate_and_prepare_dir(slot_dir)
            if not valid:
                raise RuntimeError(
                    f"Specified slot directory '{slot_dir}' cannot be validated, created, secured, or written to."
                )
            self.slot_dir = slot_dir
            self._dir_fd = dir_fd
        else:
            self.slot_dir, self._dir_fd = self._resolve_secure_slot_dir()

    @classmethod
    def _validate_and_prepare_dir(cls, path: str) -> Tuple[bool, Optional[int]]:
        """
        Validates a candidate lock directory:
        - Prevents symlink attacks using os.lstat (rejects symlinks).
        - Enforces restrictive 0700 permissions.
        - Verifies directory ownership on POSIX systems.
        - On Linux/POSIX, opens a directory file descriptor (dir_fd) with O_DIRECTORY,
          inspects inode via os.fstat(dir_fd), and uses openat for active write probe.
        - Returns (is_valid: bool, dir_fd: Optional[int]).
        """
        try:
            # Reject symlinks immediately
            if os.path.islink(path):
                return False, None

            try:
                st = os.lstat(path)
                if stat.S_ISLNK(st.st_mode) or not stat.S_ISDIR(st.st_mode):
                    return False, None
            except FileNotFoundError:
                os.makedirs(path, mode=0o700, exist_ok=True)
                st = os.lstat(path)
                if stat.S_ISLNK(st.st_mode) or not stat.S_ISDIR(st.st_mode):
                    return False, None

            # On POSIX systems with openat/dir_fd support, pin the directory inode via dir_fd
            if sys.platform != 'win32' and hasattr(os, 'supports_dir_fd') and os.open in os.supports_dir_fd:
                dir_flags = os.O_RDONLY
                if hasattr(os, 'O_DIRECTORY'):
                    dir_flags |= os.O_DIRECTORY
                if hasattr(os, 'O_CLOEXEC'):
                    dir_flags |= os.O_CLOEXEC
                if hasattr(os, 'O_NOFOLLOW'):
                    dir_flags |= os.O_NOFOLLOW

                try:
                    dir_fd = os.open(path, dir_flags)
                except OSError:
                    return False, None

                validated_successfully = False
                try:
                    fst = os.fstat(dir_fd)
                    if not stat.S_ISDIR(fst.st_mode):
                        return False, None

                    expected_uid = os.geteuid() if hasattr(os, 'geteuid') else os.getuid()
                    if fst.st_uid != expected_uid:
                        return False, None

                    os.chmod(path, 0o700)
                    fst = os.fstat(dir_fd)
                    if (fst.st_mode & 0o077) != 0:
                        return False, None

                    # Usability write/unlink probe using descriptor-relative openat(2) with O_EXCL and O_NOFOLLOW
                    probe_created = False
                    for attempt in range(3):
                        probe_name = f'.probe_{os.getpid()}_{time.monotonic_ns()}_{attempt}'
                        open_probe_flags = os.O_CREAT | os.O_EXCL | os.O_WRONLY
                        if hasattr(os, 'O_CLOEXEC'):
                            open_probe_flags |= os.O_CLOEXEC
                        if hasattr(os, 'O_NOFOLLOW'):
                            open_probe_flags |= os.O_NOFOLLOW
                        try:
                            probe_fd = os.open(probe_name, open_probe_flags, 0o600, dir_fd=dir_fd)
                            try:
                                pst = os.fstat(probe_fd)
                                if (pst.st_mode & 0o077) != 0:
                                    os.fchmod(probe_fd, 0o600)
                                    pst = os.fstat(probe_fd)
                                    if (pst.st_mode & 0o077) != 0:
                                        return False, None
                                os.write(probe_fd, b'probe')
                            finally:
                                os.close(probe_fd)
                            try:
                                os.unlink(probe_name, dir_fd=dir_fd)
                            except OSError:
                                pass
                            probe_created = True
                            break
                        except FileExistsError:
                            continue
                        except OSError:
                            return False, None

                    if not probe_created:
                        return False, None

                    validated_successfully = True
                    return True, dir_fd
                except OSError:
                    return False, None
                finally:
                    # Deterministic cleanup: if validation did not succeed, close dir_fd immediately
                    if not validated_successfully and dir_fd is not None:
                        try:
                            os.close(dir_fd)
                        except OSError:
                            pass

            else:
                # Windows / non-dir_fd POSIX fallback
                if sys.platform != 'win32':
                    expected_uid = os.geteuid() if hasattr(os, 'geteuid') else os.getuid()
                    if st.st_uid != expected_uid:
                        return False, None
                    os.chmod(path, 0o700)
                    st = os.lstat(path)
                    if (st.st_mode & 0o077) != 0:
                        return False, None

                probe_created = False
                for attempt in range(3):
                    probe_name = f'.probe_{os.getpid()}_{time.monotonic_ns()}_{attempt}'
                    probe_path = os.path.join(path, probe_name)
                    open_probe_flags = os.O_CREAT | os.O_EXCL | os.O_WRONLY
                    if hasattr(os, 'O_CLOEXEC'):
                        open_probe_flags |= os.O_CLOEXEC
                    if hasattr(os, 'O_NOFOLLOW'):
                        open_probe_flags |= os.O_NOFOLLOW
                    if hasattr(os, 'O_BINARY'):
                        open_probe_flags |= os.O_BINARY
                    try:
                        probe_fd = os.open(probe_path, open_probe_flags, 0o600)
                        try:
                            if sys.platform != 'win32':
                                pst = os.fstat(probe_fd)
                                if (pst.st_mode & 0o077) != 0:
                                    os.fchmod(probe_fd, 0o600)
                                    pst = os.fstat(probe_fd)
                                    if (pst.st_mode & 0o077) != 0:
                                        os.close(probe_fd)
                                        return False, None
                            os.write(probe_fd, b'probe')
                        finally:
                            os.close(probe_fd)
                        try:
                            os.unlink(probe_path)
                        except OSError:
                            pass
                        probe_created = True
                        break
                    except FileExistsError:
                        continue
                    except OSError:
                        return False, None

                if not probe_created:
                    return False, None

                return True, None

        except OSError:
            return False, None

    @classmethod
    def _resolve_secure_slot_dir(cls) -> Tuple[str, Optional[int]]:
        """
        Resolves an application-private directory with restrictive (0700) permissions,
        strict os.lstat symlink rejection, ownership verification, and active write probing.
        Guarantees that all concurrent Gunicorn workers under the same application identity
        share the exact same directory, avoiding split-slot isolation.
        Raises a descriptive RuntimeError if no secure directory can be established.
        """
        uid = os.getuid() if hasattr(os, 'getuid') else 'win'
        candidates = []

        # 1. POSIX XDG_RUNTIME_DIR (systemd-managed private user runtime directory)
        if sys.platform != 'win32':
            runtime_dir = os.environ.get('XDG_RUNTIME_DIR')
            if runtime_dir and os.path.isdir(runtime_dir):
                candidates.append(os.path.join(runtime_dir, 'secureai_dns_slots'))

            # 2. User home directory ~/.secureai/dns_slots
            home = os.path.expanduser('~')
            if home and os.path.isdir(home):
                candidates.append(os.path.join(home, '.secureai', 'dns_slots'))

            # 3. Application codebase directory (shared by all Gunicorn workers)
            app_dir = os.path.dirname(os.path.abspath(__file__))
            candidates.append(os.path.join(app_dir, '.secureai_dns_slots'))

            # 4. Deterministic UID-scoped fallback in temp directory (shared across workers)
            candidates.append(os.path.join(tempfile.gettempdir(), f'secureai_dns_slots_{uid}'))
        else:
            # Windows: %TEMP% is scoped per user (AppData\Local\Temp)
            candidates.append(os.path.join(tempfile.gettempdir(), 'secureai_dns_slots'))
            app_dir = os.path.dirname(os.path.abspath(__file__))
            candidates.append(os.path.join(app_dir, '.secureai_dns_slots'))

        # Ultimate deterministic shared fallback
        candidates.append(os.path.join(tempfile.gettempdir(), f'secureai_dns_fallback_{uid}'))

        for candidate in candidates:
            valid, dir_fd = cls._validate_and_prepare_dir(candidate)
            if valid:
                return candidate, dir_fd

        # Fail fast: Never silently suppress fallback failure or return an unusable directory
        raise RuntimeError(
            f"Failed to establish a secure shared cross-process lock directory. "
            f"Attempted {len(candidates)} candidates ({candidates}); all failed validation, "
            f"ownership/permission checks, or usability write probe."
        )

    def acquire(self, deadline: float) -> bool:
        """
        Attempts to acquire any of the available slots within remaining budget.
        Returns True if a slot was secured; False if saturated or timed out.
        If a filesystem error prevents opening lock files, sets self.last_error
        and aborts immediately without sleep-spinning.
        """
        with self._thread_lock:
            while time.monotonic() < deadline:
                contention = False
                for slot_idx in range(self.max_slots):
                    slot_filename = f'dns_worker_{slot_idx}.lock'
                    slot_path = os.path.join(self.slot_dir, slot_filename)
                    try:
                        if sys.platform == 'win32':
                            fd = os.open(slot_path, os.O_CREAT | os.O_RDWR)
                            import msvcrt
                            try:
                                os.lseek(fd, 0, os.SEEK_SET)
                                msvcrt.locking(fd, msvcrt.LK_NBLCK, 1)
                                self._current_slot_fd = fd
                                self._current_slot_file = slot_path
                                return True
                            except OSError:
                                # Slot is locked by a peer process (normal concurrency contention)
                                contention = True
                                os.close(fd)
                                continue
                        else:
                            open_flags = os.O_CREAT | os.O_RDWR
                            if hasattr(os, 'O_NOFOLLOW'):
                                open_flags |= os.O_NOFOLLOW
                            if hasattr(os, 'O_CLOEXEC'):
                                open_flags |= os.O_CLOEXEC

                            # Descriptor-relative openat(2) when dir_fd is available (defeats TOCTOU)
                            if self._dir_fd is not None:
                                fd = os.open(slot_filename, open_flags, 0o600, dir_fd=self._dir_fd)
                            else:
                                fd = os.open(slot_path, open_flags, 0o600)

                            # Post-open inode validation: verify regular file, single link, UID ownership, and permission bits
                            try:
                                st = os.fstat(fd)
                                if not stat.S_ISREG(st.st_mode) or st.st_nlink != 1:
                                    os.close(fd)
                                    continue
                                expected_uid = os.geteuid() if hasattr(os, 'geteuid') else os.getuid()
                                if st.st_uid != expected_uid:
                                    os.close(fd)
                                    continue
                                # Enforce restrictive permissions: group and others must have 0 access
                                if (st.st_mode & 0o077) != 0:
                                    os.fchmod(fd, 0o600)
                                    st = os.fstat(fd)
                                    if (st.st_mode & 0o077) != 0:
                                        os.close(fd)
                                        continue
                            except OSError:
                                os.close(fd)
                                continue

                            import fcntl
                            try:
                                fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
                                self._current_slot_fd = fd
                                self._current_slot_file = slot_path
                                return True
                            except OSError:
                                # Slot is locked by a peer process (normal concurrency contention)
                                contention = True
                                os.close(fd)
                                continue
                    except OSError as fs_err:
                        # Filesystem failure accessing the lock file path (e.g. read-only fs, permission error)
                        self.last_error = f"Filesystem error on lock file {slot_path}: {fs_err}"
                        return False

                if not contention:
                    # No slot could be locked and no contention occurred
                    self.last_error = f"No lock slots could be accessed in {self.slot_dir}"
                    return False

                # All slots currently occupied by peer workers: pause briefly before retrying
                time.sleep(0.04)

            return False

    def release(self) -> None:
        """Releases the acquired slot file descriptor and unlocks it."""
        if getattr(self, '_retain_locked', False):
            return
        with self._thread_lock:
            self._release_unlocked()

    def _release_unlocked(self) -> None:
        """Internal helper to release slot file descriptor without re-acquiring thread lock."""
        if getattr(self, '_retain_locked', False):
            return
        if self._current_slot_fd is not None:
            try:
                if sys.platform == 'win32':
                    import msvcrt
                    try:
                        os.lseek(self._current_slot_fd, 0, os.SEEK_SET)
                        msvcrt.locking(self._current_slot_fd, msvcrt.LK_UNLCK, 1)
                    except OSError:
                        pass
                else:
                    import fcntl
                    try:
                        fcntl.flock(self._current_slot_fd, fcntl.LOCK_UN)
                    except OSError:
                        pass
                os.close(self._current_slot_fd)
            except OSError:
                pass
            finally:
                self._current_slot_fd = None
                self._current_slot_file = None

    def close(self) -> None:
        """Releases active slot lock and closes the directory file descriptor."""
        if getattr(self, '_retain_locked', False):
            return
        with self._thread_lock:
            self._release_unlocked()
            if self._dir_fd is not None:
                try:
                    os.close(self._dir_fd)
                except OSError:
                    pass
                self._dir_fd = None

    def __del__(self) -> None:
        self.close()


# ==============================================================================
# 3. DATA STRUCTURES & VERDICT MODELS
# ==============================================================================

class VerdictType:
    SAFE_THREAT_INTEL = "SAFE_THREAT_INTEL"
    SAFE_HEURISTIC = "SAFE_HEURISTIC"
    UNVERIFIED_UGC = "UNVERIFIED_UGC"
    SUSPICIOUS = "SUSPICIOUS"
    BLOCKED_POLICY = "BLOCKED_POLICY"
    PHISHING = "PHISHING"
    MALICIOUS = "MALICIOUS"
    UNVERIFIED = "UNVERIFIED"


@dataclass
class RedirectHop:
    """Represents a single step in a URL redirection chain."""
    hop_index: int
    url: str
    resolved_ip: str
    status_code: int
    headers: Dict[str, str] = field(default_factory=dict)
    is_tls: bool = False
    latency_ms: float = 0.0
    is_ssrf_blocked: bool = False
    is_prohibited_port: bool = False
    tls_error: Optional[str] = None


@dataclass
class URLAuditResult:
    """Comprehensive analysis report for a single candidate URL."""
    original_url: str
    final_url: str
    verdict: str                  # Human-readable verdict string
    verdict_type: str             # VerdictType constant
    reasons: List[str]            # Forensic rationale and detected red flags
    is_unsafe: bool               # Backward-compatible boolean flag
    is_ssrf_blocked: bool
    is_expanded_shortener: bool
    transport_encryption: str     # "TLS Encrypted" or "Plaintext HTTP"
    threat_intel_checked: bool
    hops: List[RedirectHop] = field(default_factory=list)
    is_user_content_platform: bool = False


@dataclass
class URLAuditBatchResult:
    """Aggregate audit result across all URLs extracted from a message."""
    has_links: bool
    total_detected_links: int
    scanned_links_count: int
    omitted_links_count: int
    url_audit_timeout: bool
    threat_intel_checked: bool
    is_unsafe: bool
    first_unsafe_url: Optional[str]
    first_unsafe_reason: Optional[str]
    summary: str
    url_audits: List[URLAuditResult] = field(default_factory=list)


class SSRFPolicyViolation(Exception):
    """Raised when an IP or port violates backend SSRF network policies."""
    pass


# ==============================================================================
# 4. IP VALIDATION & SSRF DETECTION
# ==============================================================================

def is_ip_literal(host: str) -> bool:
    """Returns True if the host string is an IPv4 or IPv6 address literal."""
    cleaned = host.strip('[]')
    try:
        ipaddress.ip_address(cleaned)
        return True
    except ValueError:
        return False


def validate_ip_address(ip_str: str) -> Tuple[bool, str]:
    """
    Validates an IP string against SSRF rules and prohibited subnets.
    Handles IPv4, IPv6, and IPv4-mapped IPv6 literals (e.g. ::ffff:127.0.0.1).

    Returns:
        (is_prohibited: bool, reason: str)
    """
    cleaned = ip_str.strip('[]')
    try:
        ip_obj = ipaddress.ip_address(cleaned)
    except ValueError:
        return True, f"Malformed IP address format: {ip_str}"

    # Unwrap IPv4-mapped IPv6 addresses (e.g., ::ffff:127.0.0.1 -> 127.0.0.1)
    if isinstance(ip_obj, ipaddress.IPv6Address) and ip_obj.ipv4_mapped:
        ip_obj = ip_obj.ipv4_mapped

    if ip_obj.is_loopback:
        return True, f"Loopback address rejected: {ip_str}"
    if ip_obj.is_private:
        return True, f"Private / RFC 1918 address rejected: {ip_str}"
    if ip_obj.is_link_local:
        return True, f"Link-local / Cloud metadata address rejected: {ip_str}"
    if ip_obj.is_multicast:
        return True, f"Multicast address rejected: {ip_str}"
    if ip_obj.is_reserved:
        return True, f"Reserved address rejected: {ip_str}"
    if ip_obj.is_unspecified:
        return True, f"Unspecified network address rejected: {ip_str}"

    for network in PROHIBITED_NETWORKS:
        if ip_obj in network:
            return True, f"Prohibited subnet match ({network}): {ip_str}"

    return False, ""


def is_prohibited_port(port: int) -> bool:
    """Returns True if destination port is outside permitted HTTP/HTTPS ports."""
    return port not in PERMITTED_PORTS


def has_embedded_credentials(parsed_url) -> bool:
    """Returns True if URL contains embedded userinfo (e.g. http://user:pass@host/)."""
    return bool(parsed_url.username or parsed_url.password)


def is_ugc_domain(domain: str) -> bool:
    """Returns True if domain belongs to a recognized user-content hosting platform."""
    domain = domain.lower()
    for ugc in UGC_DOMAINS:
        if domain == ugc or domain.endswith('.' + ugc):
            return True
    return False


# ==============================================================================
# 5. PROCESS-ISOLATED DNS RESOLVER WITH GLOBAL CONCURRENCY CONTROL
# ==============================================================================

def _dns_worker_target(host: str, port: int, out_queue: mp.Queue) -> None:
    """
    Worker function executed in an isolated process to run libc getaddrinfo.
    Isolated process can be hard-terminated via process.terminate() if it hangs.
    Target function and arguments are strictly picklable under multiprocessing spawn.
    """
    try:
        # Deliberately stall hook is strictly restricted to automated test runs via environment variable
        if os.environ.get('SECUREAI_TESTING_DNS_STALL') == '1' and host.endswith('.stalled-test.internal'):
            time.sleep(30.0)
            return
        addr_info = socket.getaddrinfo(host, port, type=socket.SOCK_STREAM)
        ips = [entry[4][0] for entry in addr_info]
        out_queue.put(('OK', ips))
    except Exception as exc:
        out_queue.put(('ERR', str(exc)))


class WorkerReapError(RuntimeError):
    """Raised when an isolated DNS worker process cannot be verified dead, blocking slot release."""
    pass


def _reap_worker_proc(worker_proc: Optional[mp.Process]) -> None:
    """
    Deterministically terminates and reaps a DNS resolver worker process.
    Guarantees that the worker process is reaped (not alive) before the
    concurrency slot can be released, preventing orphaned processes from
    consuming system resolver slots while new workers run.
    If the worker cannot be confirmed reaped, raises WorkerReapError
    to explicitly block release of the concurrency slot.
    """
    if worker_proc is None or not worker_proc.is_alive():
        return

    try:
        worker_proc.terminate()
        worker_proc.join(timeout=0.2)
    except Exception:
        pass

    if worker_proc.is_alive():
        try:
            worker_proc.kill()
            worker_proc.join(timeout=0.3)
        except Exception:
            pass

    # Active polling reap loop: guarantee worker process is completely reaped before releasing lock
    if worker_proc.is_alive():
        for _ in range(10):
            time.sleep(0.05)
            if not worker_proc.is_alive():
                break
            try:
                worker_proc.kill()
                worker_proc.join(timeout=0.1)
            except Exception:
                pass

    if worker_proc.is_alive():
        # EXPLICIT FAILURE PATH: Do not allow execution to proceed to slot release
        pid_str = getattr(worker_proc, 'pid', 'unknown')
        raise WorkerReapError(
            f"DNS worker process {pid_str} remains alive after terminate and kill; "
            f"refusing to release concurrency slot lock while worker is running"
        )


_UNREAPED_SLOT_LOCKS: List[GlobalCrossProcessSlotLock] = []


def resolve_host_bounded(
    host: str,
    port: int,
    deadline: float,
    max_timeout: float = 1.5
) -> Tuple[List[str], Optional[str]]:
    """
    Resolves hostname to IP addresses under monotonic deadline and
    process-level isolation to prevent libc getaddrinfo worker starvation.
    Enforces server-wide concurrency bounding across Gunicorn workers via
    GlobalCrossProcessSlotLock. Uses explicit spawn context (mp.get_context('spawn')).
    If process isolation or lock directory fails, fails closed with UNVERIFIED.

    Returns:
        (resolved_ips: List[str], error_message: Optional[str])
    """
    # 1. Fast-flight pre-check: Is host already an IP literal?
    if is_ip_literal(host):
        prohibited, reason = validate_ip_address(host)
        if prohibited:
            return [], reason
        return [host.strip('[]')], None

    # 2. In-memory cache lookup
    now = time.monotonic()
    clean_host = host.lower().strip('.')
    if clean_host in _DNS_CACHE:
        cached_ips, exp = _DNS_CACHE[clean_host]
        if now < exp:
            return cached_ips, None
        else:
            del _DNS_CACHE[clean_host]

    # 3. Check remaining budget before acquiring server-wide concurrency slot
    remaining = deadline - now
    if remaining <= 0.05:
        return [], "DNS resolution budget exhausted (remaining <= 0.05s)"

    # Acquire server-wide cross-process concurrency slot (max 4 processes globally)
    try:
        slot_lock = GlobalCrossProcessSlotLock(max_slots=MAX_GLOBAL_DNS_WORKERS)
    except RuntimeError as dir_err:
        return [], f"DNS concurrency lock directory unavailable: {dir_err}"

    out_q: Optional[mp.Queue] = None
    worker_proc: Optional[mp.Process] = None

    try:
        try:
            acquire_deadline = now + min(max_timeout, remaining)
            acquired = slot_lock.acquire(deadline=acquire_deadline)
            if not acquired:
                if slot_lock.last_error:
                    return [], f"DNS lock initialization failed: {slot_lock.last_error}"
                return [], "Global DNS worker pool saturated (cross-worker limit reached; timed out)"

            # 4. Explicit spawn multiprocessing context for clean process isolation
            mp_ctx = mp.get_context('spawn')
            out_q = mp_ctx.Queue()

            now_worker = time.monotonic()
            remaining_worker = deadline - now_worker
            if remaining_worker <= 0.05:
                try:
                    out_q.cancel_join_thread()
                except Exception:
                    pass
                return [], "DNS resolution budget exhausted before worker spawn"

            timeout = min(max_timeout, remaining_worker)

            # Process-isolated resolution with enforceable termination under spawn context
            worker_proc = mp_ctx.Process(
                target=_dns_worker_target,
                args=(clean_host, port, out_q),
                daemon=True
            )
            worker_proc.start()
            worker_proc.join(timeout=timeout)

            if worker_proc.is_alive():
                _reap_worker_proc(worker_proc)
                # Cancel feeder thread to avoid join_thread deadlock on terminated process
                try:
                    out_q.cancel_join_thread()
                except Exception:
                    pass
                return [], f"DNS resolution timed out after {timeout:.2f}s"

            try:
                status, payload = out_q.get_nowait()
            except queue.Empty:
                try:
                    out_q.cancel_join_thread()
                except Exception:
                    pass
                return [], "DNS resolver process exited without returning data"

            if status == 'ERR':
                return [], f"DNS resolution error: {payload}"

            resolved_ips: List[str] = payload
            if not resolved_ips:
                return [], f"No IP records returned for {clean_host}"

            # 5. Dual-Stack Consensus: Check EVERY returned IP
            for ip in resolved_ips:
                prohibited, reason = validate_ip_address(ip)
                if prohibited:
                    return [], f"Dual-homed or private IP detected in DNS answer: {reason}"

            # 6. Cache clean result in LRU cache
            if len(_DNS_CACHE) >= _DNS_CACHE_MAX_ENTRIES:
                oldest_key = next(iter(_DNS_CACHE))
                del _DNS_CACHE[oldest_key]
            _DNS_CACHE[clean_host] = (resolved_ips, time.monotonic() + _DNS_CACHE_TTL_SECONDS)

            return resolved_ips, None

        except (OSError, RuntimeError) as proc_err:
            if isinstance(proc_err, WorkerReapError):
                raise
            logger.warning("DNS process spawning failed: %s", proc_err)
            if out_q is not None:
                try:
                    out_q.cancel_join_thread()
                except Exception:
                    pass
            return [], f"DNS process isolation unavailable ({proc_err}); synchronous fallback disallowed to preserve deadline"
        finally:
            if out_q is not None:
                try:
                    out_q.cancel_join_thread()
                except Exception:
                    pass
                try:
                    out_q.close()
                except Exception:
                    pass
            # GUARANTEED: Process must be confirmed reaped before slot lock is released.
            # If _reap_worker_proc raises WorkerReapError, slot_lock.close() is never reached.
            _reap_worker_proc(worker_proc)
            slot_lock.close()

    except WorkerReapError as reap_err:
        slot_lock._retain_locked = True
        _UNREAPED_SLOT_LOCKS.append(slot_lock)
        logger.critical(
            "DNS worker process %s could not be reaped; slot lock %s held permanently to prevent concurrency exhaustion: %s",
            getattr(worker_proc, 'pid', 'unknown'),
            slot_lock._current_slot_file,
            reap_err
        )
        return [], f"DNS resolution failed closed (worker un-reapable): {reap_err}"


# ==============================================================================
# 6. PINNED TRANSPORT ADAPTER & DEADLINE SOCKET WRAPPER (ANTI-REBINDING & SLOW READ DEFENSE)
# ==============================================================================

class DeadlineSocketWrapper:
    """
    Wraps an underlying transport socket (plain socket or SSLSocket) to intercept
    makefile(), recv(), and recv_into(), dynamically tuning socket timeouts before
    every read against the remaining monotonic wall-clock budget.
    Defends against Slowloris response-header trickling and unhurried body streaming.
    Ensures that when response streams close, the underlying raw_io.readinto method
    is restored to prevent object contamination, and provides update_deadline()
    so pooled/reused connections never retain stale deadlines.
    """
    def __init__(self, sock: Any, deadline: Optional[float]):
        # Prevent recursive socket wrapper nesting
        while isinstance(sock, DeadlineSocketWrapper):
            sock = sock._sock
        self._sock = sock
        self._deadline = deadline

    def close(self) -> None:
        if self._sock is not None and hasattr(self._sock, 'close'):
            self._sock.close()

    def update_deadline(self, deadline: Optional[float]) -> None:
        """Updates the deadline for reused pooled connections."""
        self._deadline = deadline

    def _check_and_set_timeout(self) -> None:
        if self._deadline is not None:
            now = time.monotonic()
            remaining = self._deadline - now
            if remaining <= 0.001:
                raise socket.timeout("Overall deadline exhausted before socket operation")
            effective_timeout = min(1.5, remaining)
            self._sock.settimeout(effective_timeout)

    def recv(self, *args, **kwargs) -> bytes:
        self._check_and_set_timeout()
        return self._sock.recv(*args, **kwargs)

    def recv_into(self, *args, **kwargs) -> int:
        self._check_and_set_timeout()
        return self._sock.recv_into(*args, **kwargs)

    def makefile(self, *args, **kwargs):
        fp = self._sock.makefile(*args, **kwargs)
        if hasattr(fp, 'raw') and hasattr(fp.raw, 'readinto') and callable(getattr(fp.raw, 'readinto', None)):
            raw_io = fp.raw
            orig_readinto = raw_io.readinto
            wrapper_self = self

            def _deadline_aware_readinto(b):
                wrapper_self._check_and_set_timeout()
                return orig_readinto(b)

            _deadline_aware_readinto._is_deadline_aware = True
            raw_io.readinto = _deadline_aware_readinto

            # Restore original readinto when fp is closed to prevent object contamination
            orig_fp_close = fp.close
            def _restoring_fp_close(*c_args, **c_kwargs):
                try:
                    if hasattr(raw_io, 'readinto') and getattr(raw_io.readinto, '_is_deadline_aware', False):
                        raw_io.readinto = orig_readinto
                except Exception:
                    pass
                return orig_fp_close(*c_args, **c_kwargs)

            fp.close = _restoring_fp_close
        return fp

    def __getattr__(self, name: str) -> Any:
        return getattr(self._sock, name)


class DeadlineHTTPConnection(urllib3.connection.HTTPConnection):
    """
    HTTPConnection subclass that enforces the remaining overall wall-clock deadline
    during TCP connection establishment, and wraps the socket in DeadlineSocketWrapper.
    """
    def _new_conn(self) -> socket.socket:
        deadline = getattr(self, '_deadline', None)
        if deadline is not None:
            remaining = deadline - time.monotonic()
            if remaining <= 0.001:
                raise socket.timeout("Overall deadline exhausted before TCP connection establishment")
            self.timeout = min(1.5, remaining)

        sock = super()._new_conn()

        if deadline is not None:
            remaining = deadline - time.monotonic()
            if remaining <= 0.001:
                try:
                    sock.close()
                except Exception:
                    pass
                raise socket.timeout("Overall deadline exhausted immediately after TCP connect")
            sock.settimeout(min(1.5, remaining))
        return sock

    def connect(self) -> None:
        deadline = getattr(self, '_deadline', None)
        if deadline is not None:
            remaining = deadline - time.monotonic()
            if remaining <= 0.001:
                raise socket.timeout("Overall deadline exhausted before HTTP connect")
            self.timeout = min(1.5, remaining)
        super().connect()
        if self.sock is not None:
            if not isinstance(self.sock, DeadlineSocketWrapper):
                self.sock = DeadlineSocketWrapper(self.sock, deadline)
            else:
                self.sock.update_deadline(deadline)


class DeadlineSSLContextProxy:
    """
    Per-connection proxy for ssl.SSLContext that intercepts wrap_socket
    to perform a non-blocking TLS handshake strictly bounded by the overall monotonic deadline.
    Defends against trickled TLS handshake record attacks where multiple small TLS records
    arrive each within inactivity timeout but cumulatively exceed the total deadline budget.
    """
    def __init__(self, target: ssl.SSLContext, deadline: Optional[float]):
        self._target = target
        self._deadline = deadline

    def __getattr__(self, name: str) -> Any:
        return getattr(self._target, name)

    def __setattr__(self, name: str, value: Any) -> None:
        if name in ('_target', '_deadline'):
            super().__setattr__(name, value)
        elif name == 'verify_mode' and value == ssl.CERT_NONE:
            try:
                self._target.check_hostname = False
            except Exception:
                pass
            self._target.verify_mode = value
        else:
            setattr(self._target, name, value)

    def wrap_socket(self, sock: socket.socket, *args, **kwargs) -> ssl.SSLSocket:
        if self._deadline is None:
            return self._target.wrap_socket(sock, *args, **kwargs)

        kwargs['do_handshake_on_connect'] = False
        ssl_sock = self._target.wrap_socket(sock, *args, **kwargs)
        ssl_sock.setblocking(False)
        try:
            while True:
                remaining = self._deadline - time.monotonic()
                if remaining <= 0.001:
                    raise socket.timeout("Overall deadline exhausted during TLS handshake")
                try:
                    ssl_sock.do_handshake()
                    break
                except ssl.SSLWantReadError:
                    timeout_val = min(1.5, max(0.001, remaining))
                    r, _, _ = select.select([ssl_sock], [], [], timeout_val)
                    if not r:
                        if (self._deadline - time.monotonic() <= 0.05) or (timeout_val >= remaining):
                            raise socket.timeout("Overall deadline exhausted during TLS handshake")
                except ssl.SSLWantWriteError:
                    timeout_val = min(1.5, max(0.001, remaining))
                    _, w, _ = select.select([], [ssl_sock], [], timeout_val)
                    if not w:
                        if (self._deadline - time.monotonic() <= 0.05) or (timeout_val >= remaining):
                            raise socket.timeout("Overall deadline exhausted during TLS handshake")
        except BaseException:
            try:
                ssl_sock.close()
            except Exception:
                pass
            raise
        ssl_sock.setblocking(True)
        return ssl_sock


class DeadlineHTTPSConnection(urllib3.connection.HTTPSConnection):
    """
    HTTPSConnection subclass that enforces the remaining overall wall-clock deadline
    during TCP connection establishment, during TLS handshake, and during data transfer.
    """
    def _new_conn(self) -> socket.socket:
        deadline = getattr(self, '_deadline', None)
        if deadline is not None:
            remaining = deadline - time.monotonic()
            if remaining <= 0.001:
                raise socket.timeout("Overall deadline exhausted before TCP connection establishment")
            self.timeout = min(1.5, remaining)

        sock = super()._new_conn()

        if deadline is not None:
            remaining = deadline - time.monotonic()
            if remaining <= 0.001:
                try:
                    sock.close()
                except Exception:
                    pass
                raise socket.timeout("Overall deadline exhausted before TLS handshake")
            # Tune socket timeout immediately before _ssl_wrap_socket_and_match_hostname executes
            sock.settimeout(min(1.5, remaining))
        return sock

    def connect(self) -> None:
        deadline = getattr(self, '_deadline', None)
        if deadline is not None:
            remaining = deadline - time.monotonic()
            if remaining <= 0.001:
                raise socket.timeout("Overall deadline exhausted before HTTPS connect")
            self.timeout = min(1.5, remaining)

        orig_ssl_context = self.ssl_context
        try:
            if deadline is not None:
                if orig_ssl_context is not None:
                    ctx = orig_ssl_context
                else:
                    ctx = urllib3.util.ssl_.create_urllib3_context(
                        ssl_version=urllib3.util.ssl_.resolve_ssl_version(self.ssl_version),
                        ssl_minimum_version=self.ssl_minimum_version,
                        ssl_maximum_version=self.ssl_maximum_version,
                        cert_reqs=urllib3.util.ssl_.resolve_cert_reqs(self.cert_reqs),
                    )
                self.ssl_context = DeadlineSSLContextProxy(ctx, deadline)
            super().connect()
        finally:
            self.ssl_context = orig_ssl_context

        if self.sock is not None:
            if not isinstance(self.sock, DeadlineSocketWrapper):
                self.sock = DeadlineSocketWrapper(self.sock, deadline)
            else:
                self.sock.update_deadline(deadline)


class DeadlineHTTPConnectionPool(HTTPConnectionPool):
    ConnectionCls = DeadlineHTTPConnection

    def _new_conn(self):
        conn = super()._new_conn()
        conn._deadline = None
        return conn

    def _make_request(self, conn, *args, deadline=None, **kwargs):
        # Refresh deadline for this specific request cycle on fresh or reused connections
        if deadline is not None:
            conn._deadline = deadline
        else:
            deadline = getattr(conn, '_deadline', None)
        if conn.sock is not None:
            if isinstance(conn.sock, DeadlineSocketWrapper):
                conn.sock.update_deadline(deadline)
            else:
                conn.sock = DeadlineSocketWrapper(conn.sock, deadline)
        return super()._make_request(conn, *args, **kwargs)

    def urlopen(self, method, url, *args, deadline=None, **response_kw):
        if deadline is not None:
            response_kw['deadline'] = deadline
            remaining = deadline - time.monotonic()
            if remaining <= 0.001:
                raise socket.timeout("Overall deadline exhausted before pool urlopen")
            effective_timeout = min(1.5, max(0.001, remaining))
            if 'timeout' not in response_kw or response_kw['timeout'] is None or response_kw['timeout'] is self.timeout:
                response_kw['timeout'] = urllib3.util.Timeout(connect=effective_timeout, read=effective_timeout)
        return super().urlopen(method, url, *args, **response_kw)


class DeadlineHTTPSConnectionPool(HTTPSConnectionPool):
    ConnectionCls = DeadlineHTTPSConnection

    def _new_conn(self):
        conn = super()._new_conn()
        conn._deadline = None
        return conn

    def _make_request(self, conn, *args, deadline=None, **kwargs):
        # Refresh deadline for this specific request cycle on fresh or reused connections
        if deadline is not None:
            conn._deadline = deadline
        else:
            deadline = getattr(conn, '_deadline', None)
        if conn.sock is not None:
            if isinstance(conn.sock, DeadlineSocketWrapper):
                conn.sock.update_deadline(deadline)
            else:
                conn.sock = DeadlineSocketWrapper(conn.sock, deadline)
        return super()._make_request(conn, *args, **kwargs)

    def urlopen(self, method, url, *args, deadline=None, **response_kw):
        if deadline is not None:
            response_kw['deadline'] = deadline
            remaining = deadline - time.monotonic()
            if remaining <= 0.001:
                raise socket.timeout("Overall deadline exhausted before pool urlopen")
            effective_timeout = min(1.5, max(0.001, remaining))
            if 'timeout' not in response_kw or response_kw['timeout'] is None or response_kw['timeout'] is self.timeout:
                response_kw['timeout'] = urllib3.util.Timeout(connect=effective_timeout, read=effective_timeout)
        return super().urlopen(method, url, *args, **response_kw)


class PinnedHTTPAdapter(HTTPAdapter):
    """
    Directs urllib3 to dial a pre-validated IP directly while preserving
    TLS Server Name Indication (SNI) and certificate hostname validation
    against the original host. Prevents TOCTOU DNS rebinding.
    Instantiates Deadline Connection Pools to wrap underlying sockets with
    DeadlineSocketWrapper, bounding HTTP header reading and body streaming.
    Caches connection pools per endpoint to enable keep-alive connection reuse
    without mutable shared pool deadline state.
    """
    def __init__(self, pinned_ip: str, original_host: str, deadline: Optional[float] = None, *args, **kwargs):
        self.pinned_ip = pinned_ip.strip('[]')
        self.original_host = original_host
        self.deadline = deadline
        self._pools: Dict[Tuple[str, str, int, str], Union[DeadlineHTTPConnectionPool, DeadlineHTTPSConnectionPool]] = {}
        self._pool_lock = threading.Lock()
        super().__init__(*args, **kwargs)

    def get_connection(self, url, proxies=None):
        parsed = requests.compat.urlparse(url)
        scheme = parsed.scheme.lower() if parsed.scheme else 'http'
        port = parsed.port or (443 if scheme == 'https' else 80)
        dial_host = self.pinned_ip
        pool_key = (scheme, dial_host, port, self.original_host)

        with self._pool_lock:
            pool = self._pools.get(pool_key)
            if pool is None:
                if scheme == 'https':
                    pool = DeadlineHTTPSConnectionPool(
                        host=dial_host,
                        port=port,
                        server_hostname=self.original_host,
                        assert_hostname=self.original_host
                    )
                else:
                    pool = DeadlineHTTPConnectionPool(host=dial_host, port=port)
                self._pools[pool_key] = pool
            return pool

    def get_connection_with_tls_context(self, request, verify, proxies=None, cert=None):
        return self.get_connection(request.url, proxies)

    def send(self, request, stream=False, timeout=None, verify=True, cert=None, proxies=None):
        req_deadline = getattr(request, '_deadline', self.deadline)

        try:
            conn = self.get_connection_with_tls_context(
                request, verify, proxies=proxies, cert=cert
            )
        except urllib3.exceptions.LocationValueError as e:
            raise requests.exceptions.InvalidURL(e, request=request)

        self.cert_verify(conn, request.url, verify, cert)
        url = self.request_url(request, proxies)
        self.add_headers(
            request,
            stream=stream,
            timeout=timeout,
            verify=verify,
            cert=cert,
            proxies=proxies,
        )

        chunked = not (request.body is None or "Content-Length" in request.headers)

        if isinstance(timeout, tuple):
            try:
                connect, read = timeout
                resolved_timeout = urllib3.util.Timeout(connect=connect, read=read)
            except ValueError:
                raise ValueError(
                    f"Invalid timeout {timeout}. Pass a (connect, read) timeout tuple, "
                    f"or a single float to set both timeouts to the same value."
                )
        elif isinstance(timeout, urllib3.util.Timeout):
            resolved_timeout = timeout
        else:
            resolved_timeout = urllib3.util.Timeout(connect=timeout, read=timeout)

        try:
            resp = conn.urlopen(
                method=request.method,
                url=url,
                body=request.body,
                headers=request.headers,
                redirect=False,
                assert_same_host=False,
                preload_content=False,
                decode_content=False,
                retries=self.max_retries,
                timeout=resolved_timeout,
                chunked=chunked,
                deadline=req_deadline,
            )
        except (urllib3.exceptions.ProtocolError, OSError) as err:
            raise requests.exceptions.ConnectionError(err, request=request)
        except urllib3.exceptions.MaxRetryError as e:
            if isinstance(e.reason, urllib3.exceptions.ConnectTimeoutError):
                if not isinstance(e.reason, urllib3.exceptions.NewConnectionError):
                    raise requests.exceptions.ConnectTimeout(e, request=request)
            if isinstance(e.reason, urllib3.exceptions.ResponseError):
                raise requests.exceptions.RetryError(e, request=request)
            if isinstance(e.reason, urllib3.exceptions.ProxyError):
                raise requests.exceptions.ProxyError(e, request=request)
            if isinstance(e.reason, urllib3.exceptions.SSLError):
                raise requests.exceptions.SSLError(e, request=request)
            raise requests.exceptions.ConnectionError(e, request=request)
        except urllib3.exceptions.ClosedPoolError as e:
            raise requests.exceptions.ConnectionError(e, request=request)
        except urllib3.exceptions.ProxyError as e:
            raise requests.exceptions.ProxyError(e)
        except (urllib3.exceptions.SSLError, urllib3.exceptions.HTTPError) as e:
            if isinstance(e, urllib3.exceptions.SSLError):
                raise requests.exceptions.SSLError(e, request=request)
            elif isinstance(e, urllib3.exceptions.ReadTimeoutError):
                raise requests.exceptions.ReadTimeout(e, request=request)
            else:
                raise

        return self.build_response(request, resp)

    def close(self):
        with self._pool_lock:
            for pool in self._pools.values():
                pool.close()
            self._pools.clear()
        super().close()


# ==============================================================================
# 7. HOP-BY-HOP REDIRECT TRAVERSAL & SLOW-TRICKLE BODY STREAMING
# ==============================================================================

def safe_resolve_redirects(
    start_url: str,
    deadline: float,
    max_hops: int = MAX_REDIRECT_HOPS
) -> Tuple[str, List[RedirectHop], Optional[str], Optional[str]]:
    """
    Safely resolves HTTP redirects hop-by-hop with per-hop SSRF validation,
    pinned IP transport, cycle detection, response-size clamps, slow-trickle socket
    timeout tuning, and bounded wall-clock deadline enforcement (<= 50ms scheduling tolerance).

    Returns:
        (final_url: str, hops: List[RedirectHop], halt_reason: Optional[str], halt_verdict: Optional[str])
    """
    current_url = start_url.strip()
    hops: List[RedirectHop] = []
    visited_urls: Set[str] = set()

    for hop_idx in range(1, max_hops + 1):
        now = time.monotonic()
        remaining = deadline - now
        if remaining <= 0.05:
            return current_url, hops, "Overall audit deadline exhausted during redirection", VerdictType.UNVERIFIED

        # Check explicit scheme: Reject non-HTTP schemes as BLOCKED_POLICY without mangling
        raw_parsed = urlparse(current_url)
        raw_scheme = raw_parsed.scheme.lower() if raw_parsed.scheme else ""

        if raw_scheme:
            if raw_scheme not in ('http', 'https'):
                return current_url, hops, f"Prohibited URL scheme: {raw_scheme}", VerdictType.BLOCKED_POLICY
        else:
            # Scheme-less domain: safely prefix https://
            current_url = 'https://' + current_url

        parsed = urlparse(current_url)

        # Check port
        port = parsed.port or (443 if parsed.scheme == 'https' else 80)
        if is_prohibited_port(port):
            return current_url, hops, f"Prohibited destination port: {port}", VerdictType.BLOCKED_POLICY

        # Check userinfo
        if has_embedded_credentials(parsed):
            return current_url, hops, "Embedded credentials detected in URL userinfo", VerdictType.SUSPICIOUS

        host = parsed.hostname
        if not host:
            return current_url, hops, "Malformed URL: missing hostname", VerdictType.UNVERIFIED

        # Detect cycle
        if current_url in visited_urls:
            return current_url, hops, f"Redirect cycle detected: loop back to {current_url}", VerdictType.SUSPICIOUS
        visited_urls.add(current_url)

        # Resolve host under deadline
        resolved_ips, dns_err = resolve_host_bounded(host, port, deadline)
        if dns_err:
            if "Dual-homed or private IP" in dns_err or "prohibited" in dns_err.lower():
                return current_url, hops, dns_err, VerdictType.BLOCKED_POLICY
            if "timed out" in dns_err.lower() or "budget exhausted" in dns_err.lower() or "saturated" in dns_err.lower():
                return current_url, hops, dns_err, VerdictType.UNVERIFIED
            return current_url, hops, dns_err, VerdictType.UNVERIFIED

        pinned_ip = resolved_ips[0]
        is_tls = parsed.scheme == 'https'
        hop_start = time.monotonic()

        # Check remaining budget before network dialing
        remaining_for_dial = deadline - time.monotonic()
        if remaining_for_dial <= 0.05:
            return current_url, hops, "Deadline exhausted before network connection", VerdictType.UNVERIFIED

        # Socket timeout is strictly bounded by remaining deadline (never exceeds remaining)
        socket_timeout = min(1.5, remaining_for_dial)

        # Build isolated session
        session = requests.Session()
        session.trust_env = False  # Prevent upstream proxy bypass
        session.proxies = {}

        adapter = PinnedHTTPAdapter(pinned_ip, host, deadline=deadline)
        session.mount('https://', adapter)
        session.mount('http://', adapter)

        response: Optional[requests.Response] = None
        tls_error_msg: Optional[str] = None

        try:
            # 1. Attempt HEAD request
            response = session.head(
                current_url,
                timeout=socket_timeout,
                allow_redirects=False,
                verify=True
            )

            # 2. Fallback to GET with 64 KB streaming if HEAD is disallowed (405)
            if response.status_code == 405:
                remaining_get = deadline - time.monotonic()
                if remaining_get <= 0.05:
                    return current_url, hops, "Deadline exhausted before GET fallback", VerdictType.UNVERIFIED

                get_socket_timeout = min(1.5, remaining_get)
                response = session.get(
                    current_url,
                    timeout=get_socket_timeout,
                    allow_redirects=False,
                    stream=True,
                    verify=True
                )
                total_bytes = 0

                # Dynamic per-read socket timeout tuning:
                # Intercepts every low-level socket read via SocketIO.readinto to guarantee
                # that the OS socket timeout is refreshed before every blocking read,
                # bounding reads by remaining overall deadline without relying on an external watchdog.
                raw_io = None
                sock = None
                orig_readinto = None
                hook_installed = False

                if hasattr(response, 'raw') and response.raw is not None:
                    fp = getattr(response.raw, '_fp', None)
                    if fp and hasattr(fp, 'fp') and fp.fp:
                        raw_io = getattr(fp.fp, 'raw', None)
                        if raw_io and hasattr(raw_io, '_sock'):
                            sock = raw_io._sock

                # Strict Fail-Closed: If the low-level socket stream or readinto method cannot be accessed,
                # refuse to proceed with unbounded streaming and return UNVERIFIED immediately.
                if raw_io is None or sock is None or not hasattr(raw_io, 'readinto') or not callable(getattr(raw_io, 'readinto', None)):
                    try:
                        if response and response.raw is not None:
                            response.close()
                    except Exception:
                        pass
                    return current_url, hops, "Streaming socket deadline hook unavailable; failing closed to prevent unbounded read", VerdictType.UNVERIFIED

                # If raw_io was not already wrapped by DeadlineSocketWrapper, install per-read tuning
                if not getattr(raw_io.readinto, '_is_deadline_aware', False):
                    def _deadline_aware_readinto(b):
                        now = time.monotonic()
                        remaining = deadline - now
                        # Explicit near-expiry check: if less than 1ms (0.001s) remains,
                        # there is insufficient budget for an OS network read without exceeding deadline.
                        # Fail fast immediately with socket.timeout.
                        if remaining <= 0.001:
                            raise socket.timeout("Overall deadline exhausted before socket read")

                        # Dynamic per-read timeout strictly bounded by remaining budget.
                        # Since remaining > 0.001, effective_timeout is strictly <= remaining.
                        effective_timeout = min(1.5, remaining)
                        sock.settimeout(effective_timeout)
                        return orig_readinto(b)

                    _deadline_aware_readinto._is_deadline_aware = True

                    try:
                        orig_readinto = raw_io.readinto
                        raw_io.readinto = _deadline_aware_readinto
                        hook_installed = True
                    except (AttributeError, TypeError) as hook_err:
                        try:
                            if response and response.raw is not None:
                                response.close()
                        except Exception:
                            pass
                        return current_url, hops, f"Streaming socket hook installation failed ({hook_err}); failing closed", VerdictType.UNVERIFIED

                try:
                    for chunk in response.iter_content(chunk_size=STREAM_CHUNK_SIZE):
                        total_bytes += len(chunk)
                        if time.monotonic() >= deadline:
                            return current_url, hops, "Deadline exceeded while streaming response body", VerdictType.UNVERIFIED
                        if total_bytes >= MAX_BODY_STREAM_BYTES:
                            break
                except (requests.exceptions.Timeout, requests.exceptions.ConnectionError, socket.timeout, OSError) as stream_err:
                    if time.monotonic() >= deadline or "timeout" in str(stream_err).lower() or "timed out" in str(stream_err).lower():
                        return current_url, hops, "Deadline exceeded while streaming response body", VerdictType.UNVERIFIED
                    logger.debug("Stream aborted by socket timeout or error: %s", stream_err)
                finally:
                    # Restore original readinto method if hook was installed to prevent object contamination
                    if hook_installed and raw_io is not None and orig_readinto is not None:
                        try:
                            raw_io.readinto = orig_readinto
                        except Exception:
                            pass
                    try:
                        if response and response.raw is not None:
                            response.close()
                    except Exception:
                        pass

        except requests.exceptions.SSLError as ssl_err:
            tls_error_msg = f"TLS Verification Failed: {ssl_err}"
            hop = RedirectHop(
                hop_index=hop_idx,
                url=current_url,
                resolved_ip=pinned_ip,
                status_code=0,
                headers={},
                is_tls=is_tls,
                latency_ms=(time.monotonic() - hop_start) * 1000.0,
                tls_error=tls_error_msg
            )
            hops.append(hop)
            return current_url, hops, tls_error_msg, VerdictType.SUSPICIOUS

        except requests.exceptions.Timeout as timeout_err:
            return current_url, hops, f"Request timed out connecting to {pinned_ip}: {timeout_err}", VerdictType.UNVERIFIED

        except requests.exceptions.RequestException as req_err:
            return current_url, hops, f"Connection failed to {pinned_ip}: {req_err}", VerdictType.UNVERIFIED

        finally:
            session.close()

        latency_ms = (time.monotonic() - hop_start) * 1000.0
        hop = RedirectHop(
            hop_index=hop_idx,
            url=current_url,
            resolved_ip=pinned_ip,
            status_code=response.status_code if response else 0,
            headers=dict(response.headers) if response else {},
            is_tls=is_tls,
            latency_ms=latency_ms
        )
        hops.append(hop)

        # Check for HTTP redirect status codes (301, 302, 303, 307, 308)
        if response and response.status_code in (301, 302, 303, 307, 308):
            location = response.headers.get('Location')
            if not location or not location.strip():
                return current_url, hops, f"Malformed redirect ({response.status_code}) with missing Location header", VerdictType.UNVERIFIED

            # Resolve relative redirects
            next_url = urljoin(current_url, location.strip())
            current_url = next_url

            if hop_idx == max_hops:
                return current_url, hops, f"Redirect chain exceeded {max_hops} hops", VerdictType.SUSPICIOUS
        else:
            # Non-redirect response: Destination reached. Verify HTTP status code.
            if response is None:
                return current_url, hops, "No HTTP response received from server", VerdictType.UNVERIFIED
            # HTTP 4xx and 5xx responses must produce UNVERIFIED (cannot be verified as safe functioning services)
            if response.status_code >= 400:
                return current_url, hops, f"HTTP server error ({response.status_code})", VerdictType.UNVERIFIED

            # Valid 2xx response: Destination verified
            return current_url, hops, None, None

    return current_url, hops, None, None


# ==============================================================================
# 8. GOOGLE SAFE BROWSING V4 INTEGRATION (OPTIONAL)
# ==============================================================================

def check_google_safe_browsing(
    urls: List[str],
    deadline: float
) -> Tuple[Dict[str, str], bool]:
    """
    Queries Google Safe Browsing Lookup API v4 in batch if API key is present.

    Returns:
        (matches: Dict[url, threat_type], api_checked: bool)
    """
    api_key = os.environ.get('GOOGLE_SAFE_BROWSING_API_KEY')
    if not api_key:
        return {}, False

    remaining = deadline - time.monotonic()
    if remaining <= 0.25 or not urls:
        return {}, False

    endpoint = f"https://safebrowsing.googleapis.com/v4/threatMatches:find?key={api_key}"
    payload = {
        "client": {
            "clientId": "secureai-threat-engine",
            "clientVersion": "2.0.0"
        },
        "threatInfo": {
            "threatTypes": [
                "MALWARE", "SOCIAL_ENGINEERING", "UNWANTED_SOFTWARE", "POTENTIALLY_HARMFUL_APPLICATION"
            ],
            "platformTypes": ["ANY_PLATFORM"],
            "threatEntryTypes": ["URL"],
            "threatEntries": [{"url": u} for u in urls[:MAX_SCANNED_URLS]]
        }
    }

    try:
        timeout = min(1.0, remaining)
        resp = requests.post(endpoint, json=payload, timeout=timeout)
        if resp.status_code == 200:
            data = resp.json()
            matches = {}
            for match in data.get('matches', []):
                matched_url = match.get('threat', {}).get('url')
                threat_type = match.get('threatType', 'MALICIOUS')
                if matched_url:
                    matches[matched_url] = threat_type
            return matches, True
        else:
            logger.warning("Safe Browsing API returned status %d", resp.status_code)
            return {}, False
    except Exception as exc:
        logger.warning("Safe Browsing query failed: %s", exc)
        return {}, False


# ==============================================================================
# 9. MULTI-SIGNAL VERDICT CONSENSUS
# ==============================================================================

def evaluate_url_verdict(
    original_url: str,
    final_url: str,
    hops: List[RedirectHop],
    halt_reason: Optional[str],
    halt_verdict: Optional[str],
    threat_intel_match: Optional[str],
    threat_intel_checked: bool
) -> URLAuditResult:
    """
    Synthesizes multi-signal consensus across SSRF checks, redirect hops,
    lexical heuristics, user-content policies, and threat intelligence.
    """
    reasons: List[str] = []
    parsed_final = urlparse(final_url)
    final_domain = (parsed_final.hostname or "").lower()

    # Determine transport encryption
    is_tls = parsed_final.scheme == 'https'
    transport_enc = "TLS Encrypted" if is_tls else "Plaintext HTTP"

    is_shortener = any(final_domain == s or final_domain.endswith('.' + s) for s in KNOWN_SHORTENERS)
    is_ugc = is_ugc_domain(final_domain)
    is_expanded = len(hops) > 1

    # 1. Immediate Security Policy Violations (SSRF / Prohibited Port / Scheme)
    if halt_verdict == VerdictType.BLOCKED_POLICY:
        return URLAuditResult(
            original_url=original_url,
            final_url=final_url,
            verdict="Blocked (Security Policy Violation)",
            verdict_type=VerdictType.BLOCKED_POLICY,
            reasons=[halt_reason or "Destination violates network security policy."],
            is_unsafe=True,
            is_ssrf_blocked=True,
            is_expanded_shortener=is_expanded,
            transport_encryption=transport_enc,
            threat_intel_checked=threat_intel_checked,
            hops=hops,
            is_user_content_platform=is_ugc
        )

    # 2. Confirmed External Threat Intelligence Match (Takes precedence over network errors)
    if threat_intel_match:
        reasons.append(f"Google Safe Browsing confirmed match: {threat_intel_match}")
        return URLAuditResult(
            original_url=original_url,
            final_url=final_url,
            verdict=f"Malicious ({threat_intel_match})",
            verdict_type=VerdictType.MALICIOUS if "MALWARE" in threat_intel_match else VerdictType.PHISHING,
            reasons=reasons,
            is_unsafe=True,
            is_ssrf_blocked=False,
            is_expanded_shortener=is_expanded,
            transport_encryption=transport_enc,
            threat_intel_checked=threat_intel_checked,
            hops=hops,
            is_user_content_platform=is_ugc
        )

    # 3. Suspicious Redirect or Transport Behavior
    if halt_verdict == VerdictType.SUSPICIOUS:
        return URLAuditResult(
            original_url=original_url,
            final_url=final_url,
            verdict="Suspicious (Redirect Anomaly)",
            verdict_type=VerdictType.SUSPICIOUS,
            reasons=[halt_reason or "Suspicious redirect behavior detected."],
            is_unsafe=True,
            is_ssrf_blocked=False,
            is_expanded_shortener=is_expanded,
            transport_encryption=transport_enc,
            threat_intel_checked=threat_intel_checked,
            hops=hops,
            is_user_content_platform=is_ugc
        )

    # 4. Unverified Network Errors, Timeouts, or HTTP 4xx/5xx Responses
    if halt_verdict == VerdictType.UNVERIFIED:
        return URLAuditResult(
            original_url=original_url,
            final_url=final_url,
            verdict="Unverified (Network or Audit Error)",
            verdict_type=VerdictType.UNVERIFIED,
            reasons=[halt_reason or "Could not complete resolution."],
            is_unsafe=False,
            is_ssrf_blocked=False,
            is_expanded_shortener=is_expanded,
            transport_encryption=transport_enc,
            threat_intel_checked=threat_intel_checked,
            hops=hops,
            is_user_content_platform=is_ugc
        )

    # 5. Lexical & Heuristic Evaluations
    has_suspicious_tld = any(final_domain.endswith(tld) for tld in SUSPICIOUS_TLDS)
    path_and_query = (parsed_final.path + " " + parsed_final.query).lower()
    found_keywords = [kw for kw in HIGH_RISK_KEYWORDS if kw in path_and_query or kw in final_domain]

    # Brand impersonation check
    spoofed_brands = [
        brand for brand in POPULAR_BRANDS
        if brand in final_domain and not final_domain.endswith(f".{brand}.com") and final_domain != f"{brand}.com"
    ]

    if spoofed_brands:
        reasons.append(f"Potential brand impersonation detected for: {', '.join(spoofed_brands)}")
    if has_suspicious_tld:
        reasons.append(f"High-risk top-level domain (. {final_domain.split('.')[-1]}) detected.")
    if found_keywords and (has_suspicious_tld or spoofed_brands):
        reasons.append(f"Sensitive credential keywords in URL: {', '.join(found_keywords)}")

    # Unexpanded shortlink remaining at destination
    if is_shortener and not is_expanded:
        reasons.append(f"Known shortener domain '{final_domain}' remained unexpanded.")
        return URLAuditResult(
            original_url=original_url,
            final_url=final_url,
            verdict="Suspicious (Unresolved Redirect)",
            verdict_type=VerdictType.SUSPICIOUS,
            reasons=reasons,
            is_unsafe=True,
            is_ssrf_blocked=False,
            is_expanded_shortener=False,
            transport_encryption=transport_enc,
            threat_intel_checked=threat_intel_checked,
            hops=hops,
            is_user_content_platform=is_ugc
        )

    if spoofed_brands or (has_suspicious_tld and found_keywords):
        return URLAuditResult(
            original_url=original_url,
            final_url=final_url,
            verdict="Suspicious",
            verdict_type=VerdictType.SUSPICIOUS,
            reasons=reasons,
            is_unsafe=True,
            is_ssrf_blocked=False,
            is_expanded_shortener=is_expanded,
            transport_encryption=transport_enc,
            threat_intel_checked=threat_intel_checked,
            hops=hops,
            is_user_content_platform=is_ugc
        )

    # 6. User-Generated Content Platform Policy
    if is_ugc:
        reasons.append(f"Destination '{final_domain}' is a legitimate cloud hosting platform.")
        reasons.append("Hosted user content or form fields cannot be verified without inspection.")
        return URLAuditResult(
            original_url=original_url,
            final_url=final_url,
            verdict="Unverified (User-Hosted Content)",
            verdict_type=VerdictType.UNVERIFIED_UGC,
            reasons=reasons,
            is_unsafe=False,
            is_ssrf_blocked=False,
            is_expanded_shortener=is_expanded,
            transport_encryption=transport_enc,
            threat_intel_checked=threat_intel_checked,
            hops=hops,
            is_user_content_platform=True
        )

    # 7. Clean Consensus: Threat Intel Verified vs Heuristic Verified
    if threat_intel_checked:
        reasons.append("All hops resolved cleanly. Threat intelligence API confirmed zero threat matches.")
        return URLAuditResult(
            original_url=original_url,
            final_url=final_url,
            verdict="Safe (Threat Intel Verified)",
            verdict_type=VerdictType.SAFE_THREAT_INTEL,
            reasons=reasons,
            is_unsafe=False,
            is_ssrf_blocked=False,
            is_expanded_shortener=is_expanded,
            transport_encryption=transport_enc,
            threat_intel_checked=True,
            hops=hops,
            is_user_content_platform=False
        )
    else:
        reasons.append("All hops resolved cleanly. Passed heuristic and structural security checks.")
        reasons.append("Threat intelligence API unconfigured or offline; independent clearance unavailable.")
        return URLAuditResult(
            original_url=original_url,
            final_url=final_url,
            verdict="Safe (Heuristic Verified)",
            verdict_type=VerdictType.SAFE_HEURISTIC,
            reasons=reasons,
            is_unsafe=False,
            is_ssrf_blocked=False,
            is_expanded_shortener=is_expanded,
            transport_encryption=transport_enc,
            threat_intel_checked=False,
            hops=hops,
            is_user_content_platform=False
        )


# ==============================================================================
# 10. BATCH AUDIT CONTROLLER
# ==============================================================================

def extract_urls(text: str) -> List[str]:
    """
    Extracts unique HTTP/HTTPS, domain, IPv4, and IPv6 formatted URLs from text.
    Preserves embedded credentials (user:pass@) while distinguishing and excluding
    email addresses (e.g. user@domain.com).
    """
    if not text:
        return []

    # 1. Identify all email addresses in text to protect against email domain splitting
    email_pattern = re.compile(r'[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+')
    emails = set(email_pattern.findall(text))

    # 2. Extract full URLs, schemes, userinfo, IP addresses, and scheme-less domains
    url_pattern = re.compile(
        r'(?:'
        # Explicit scheme with optional userinfo and optional host:
        r'[a-zA-Z][a-zA-Z0-9+.-]*:\/\/(?:[^\s:@/]+(?::[^\s:@/]*)?@)?'
        r'(?:(?:[a-zA-Z0-9_-]+\.)+[a-zA-Z]{2,}|\d{1,3}(?:\.\d{1,3}){3}|\[[a-fA-F0-9:]+\]|[a-zA-Z0-9_-]+)?'
        r'(?::\d+)?(?:\/[^\s"\'<>]*)?'
        r'|'
        # javascript: URIs
        r'javascript:[^\s"\'<>]+'
        r'|'
        # Scheme-less domains
        r'(?:[a-zA-Z0-9_-]+\.)+[a-zA-Z]{2,}(?::\d+)?(?:\/[^\s"\'<>]*)?'
        r'|'
        r'\d{1,3}(?:\.\d{1,3}){3}(?::\d+)?(?:\/[^\s"\'<>]*)?'
        r'|'
        r'\[[a-fA-F0-9:]+\](?::\d+)?(?:\/[^\s"\'<>]*)?'
        r')',
        re.IGNORECASE
    )

    raw_matches = url_pattern.findall(text)
    seen: Set[str] = set()
    cleaned_urls: List[str] = []

    for match in raw_matches:
        u = match.strip()
        while u and u[-1] in '.,;:!?"\'':
            u = u[:-1]
        if u.endswith(')') and '(' not in u:
            u = u[:-1]

        if not u:
            continue

        # Avoid matching local-parts or domain portions of standalone email addresses
        is_email_fragment = False
        for em in emails:
            if u in em and not u.startswith(('http://', 'https://', 'ftp://', 'file://', 'javascript:')):
                is_email_fragment = True
                break
        if is_email_fragment:
            continue

        if u not in seen:
            seen.add(u)
            cleaned_urls.append(u)

    return cleaned_urls


def audit_all_urls(
    text: str,
    deadline_seconds: float = OVERALL_BUDGET_SECONDS,
    max_links: int = MAX_SCANNED_URLS
) -> URLAuditBatchResult:
    """
    Main entry point for link auditing in SMS and Email processing views.
    Enforces a strict wall-clock deadline across extraction, traversal, and threat intel.
    """
    deadline = time.monotonic() + deadline_seconds
    extracted = extract_urls(text)
    total_detected = len(extracted)

    if not extracted:
        return URLAuditBatchResult(
            has_links=False,
            total_detected_links=0,
            scanned_links_count=0,
            omitted_links_count=0,
            url_audit_timeout=False,
            threat_intel_checked=False,
            is_unsafe=False,
            first_unsafe_url=None,
            first_unsafe_reason=None,
            summary="No links detected in content.",
            url_audits=[]
        )

    scanned_candidates = extracted[:max_links]
    omitted_count = max(0, total_detected - len(scanned_candidates))

    # Phase 2: Hop traversal
    traversal_results: List[Tuple[str, str, List[RedirectHop], Optional[str], Optional[str]]] = []
    final_urls_for_intel: List[str] = []
    audit_timed_out = False

    for candidate in scanned_candidates:
        if time.monotonic() >= deadline:
            audit_timed_out = True
            break
        final_url, hops, halt_reason, halt_verdict = safe_resolve_redirects(candidate, deadline)
        traversal_results.append((candidate, final_url, hops, halt_reason, halt_verdict))
        final_urls_for_intel.append(final_url)
        if (halt_verdict == VerdictType.UNVERIFIED and halt_reason and "deadline" in halt_reason.lower()) or time.monotonic() >= deadline:
            audit_timed_out = True
            break

    if time.monotonic() >= deadline:
        audit_timed_out = True

    # Phase 3: External Threat Intelligence (Google Safe Browsing batch call)
    threat_matches: Dict[str, str] = {}
    threat_intel_checked = False
    if final_urls_for_intel and time.monotonic() < deadline:
        threat_matches, threat_intel_checked = check_google_safe_browsing(final_urls_for_intel, deadline)

    # Phase 4: Multi-Signal Synthesis
    audited_objects: List[URLAuditResult] = []
    has_any_unsafe = False
    first_unsafe_url: Optional[str] = None
    first_unsafe_reason: Optional[str] = None

    for candidate, final_url, hops, halt_reason, halt_verdict in traversal_results:
        match_type = threat_matches.get(final_url) or threat_matches.get(candidate)
        audit_res = evaluate_url_verdict(
            original_url=candidate,
            final_url=final_url,
            hops=hops,
            halt_reason=halt_reason,
            halt_verdict=halt_verdict,
            threat_intel_match=match_type,
            threat_intel_checked=threat_intel_checked
        )
        audited_objects.append(audit_res)

        if audit_res.is_unsafe and not has_any_unsafe:
            has_any_unsafe = True
            first_unsafe_url = audit_res.original_url
            first_unsafe_reason = audit_res.reasons[0] if audit_res.reasons else audit_res.verdict

    # Build accounting summary
    summary_parts = [f"Audited {len(audited_objects)} of {total_detected} links."]
    if omitted_count > 0:
        summary_parts.append(f"{omitted_count} links omitted due to scan threshold ({max_links}).")
    if audit_timed_out:
        summary_parts.append("Scan halted due to 5.0-second deadline.")
    if has_any_unsafe:
        summary_parts.append(f"Security Alert: Unsafe destination detected ({first_unsafe_reason}).")
    else:
        summary_parts.append("No active security policy violations or malware signatures confirmed.")

    return URLAuditBatchResult(
        has_links=True,
        total_detected_links=total_detected,
        scanned_links_count=len(audited_objects),
        omitted_links_count=omitted_count,
        url_audit_timeout=audit_timed_out,
        threat_intel_checked=threat_intel_checked,
        is_unsafe=has_any_unsafe,
        first_unsafe_url=first_unsafe_url,
        first_unsafe_reason=first_unsafe_reason,
        summary=" ".join(summary_parts),
        url_audits=audited_objects
    )
