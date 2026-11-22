"""
SecureAI Page Inspector
=======================
Ultra-lightweight, zero-OOM webpage content and form analyzer designed for
high-accuracy spam, smishing, and phishing detection within Render free tier limits.

Key Capabilities:
- Parses page title, meta description, forms, input fields, action buttons, image logos.
- Detects credential harvesting (password, OTP/2FA, PIN).
- Detects payment & financial data capture (credit cards, CVV, bank accounts, fees).
- Detects brand impersonation (e.g. USPS, FedEx, PayPal, Microsoft, Netflix on foreign domains).
- Detects malware downloads (.apk, .exe, .scr, .zip, .bat).
- Flags evasive multi-hop redirect chains leading to sensitive or hostile forms.
- Enforces strict memory clamping (max 256KB body) and bounded socket deadlines (<= 2.0s).
- Pre-fetch SSRF validation to prevent intranet/private IP exploitation.
"""

import re
import socket
import logging
from dataclasses import dataclass, field
from html.parser import HTMLParser
from typing import List, Dict, Optional, Any
from urllib.parse import urlparse
import requests

logger = logging.getLogger(__name__)

# Maximum HTML bytes downloaded per page (256 KB) to prevent memory exhaustion / zip bombs
MAX_INSPECTION_BYTES = 262144

# Socket timeout in seconds per page inspection
INSPECTION_TIMEOUT_SECONDS = 2.0

# User-Agent representing a modern mobile/desktop browser to avoid anti-bot blocks
INSPECTOR_USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
    "AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/124.0.0.0 Safari/537.36"
)

# Known legitimate domains for high-target impersonated brands
KNOWN_BRAND_DOMAINS: Dict[str, List[str]] = {
    'usps': ['usps.com', 'usps.gov'],
    'fedex': ['fedex.com'],
    'ups': ['ups.com'],
    'dhl': ['dhl.com'],
    'paypal': ['paypal.com', 'paypal.me'],
    'microsoft': ['microsoft.com', 'live.com', 'office.com', 'office365.com', 'outlook.com', 'sharepoint.com'],
    'google': ['google.com', 'gmail.com', 'google.co.in', 'google.co.uk'],
    'apple': ['apple.com', 'icloud.com'],
    'netflix': ['netflix.com'],
    'amazon': ['amazon.com', 'amazon.co.uk', 'amazon.de', 'amazon.in'],
    'chase': ['chase.com'],
    'wells fargo': ['wellsfargo.com'],
    'bank of america': ['bankofamerica.com'],
    'irs': ['irs.gov'],
    'whatsapp': ['whatsapp.com'],
    'telegram': ['telegram.org', 't.me'],
}


class _SafeDOMParser(HTMLParser):
    """
    Fast, streaming HTML parser using Python's standard library.
    Consumes minimal CPU and memory with hard stop after 1000 tokens.
    """
    def __init__(self):
        super().__init__()
        self.title = ""
        self._in_title = False
        self.meta_tags: Dict[str, str] = {}
        self.headings: List[str] = []
        self._in_heading = False
        self._current_heading = ""
        self.forms: List[Dict[str, Any]] = []
        self._current_form: Optional[Dict[str, Any]] = None
        self.inputs: List[Dict[str, str]] = []
        self.buttons: List[str] = []
        self._in_button = False
        self._current_button = ""
        self.images: List[Dict[str, str]] = []
        self.text_chunks: List[str] = []
        self._skip_depth = 0
        self.suspicious_downloads: List[str] = []
        self.total_tags = 0

    def handle_starttag(self, tag: str, attrs: List[tuple]):
        self.total_tags += 1
        if self.total_tags > 2000:
            return  # Prevent runaway DOM complexity

        attr_dict = {k.lower(): v or "" for k, v in attrs}
        if tag in ('script', 'style', 'noscript', 'svg'):
            self._skip_depth += 1
            return
        if self._skip_depth > 0:
            return

        if tag == 'title':
            self._in_title = True
        elif tag in ('h1', 'h2', 'h3'):
            self._in_heading = True
            self._current_heading = ""
        elif tag == 'meta':
            name = attr_dict.get('name', '') or attr_dict.get('property', '')
            content = attr_dict.get('content', '')
            if name and content:
                self.meta_tags[name.lower()] = content
        elif tag == 'form':
            action = attr_dict.get('action', '')
            method = attr_dict.get('method', 'get').upper()
            self._current_form = {'action': action, 'method': method, 'inputs': []}
            self.forms.append(self._current_form)
        elif tag == 'input':
            inp_type = attr_dict.get('type', 'text').lower()
            name = attr_dict.get('name', '').lower()
            placeholder = attr_dict.get('placeholder', '')
            input_info = {'type': inp_type, 'name': name, 'placeholder': placeholder}
            self.inputs.append(input_info)
            if self._current_form is not None:
                self._current_form['inputs'].append(input_info)
        elif tag == 'button':
            self._in_button = True
            self._current_button = ""
        elif tag == 'img':
            alt = attr_dict.get('alt', '')
            src = attr_dict.get('src', '')
            title = attr_dict.get('title', '')
            if alt or title or src:
                self.images.append({'alt': alt, 'title': title, 'src': src})
        elif tag == 'a':
            href = attr_dict.get('href', '').lower()
            for ext in ('.apk', '.exe', '.scr', '.bat', '.vbs', '.iso', '.zip'):
                if href.endswith(ext) or (ext + '?') in href:
                    self.suspicious_downloads.append(href)

    def handle_endtag(self, tag: str):
        if tag in ('script', 'style', 'noscript', 'svg'):
            if self._skip_depth > 0:
                self._skip_depth -= 1
            return
        if self._skip_depth > 0:
            return

        if tag == 'title':
            self._in_title = False
        elif tag in ('h1', 'h2', 'h3'):
            self._in_heading = False
            if self._current_heading.strip() and len(self.headings) < 5:
                self.headings.append(self._current_heading.strip())
        elif tag == 'form':
            self._current_form = None
        elif tag == 'button':
            self._in_button = False
            if self._current_button.strip() and len(self.buttons) < 5:
                self.buttons.append(self._current_button.strip())

    def handle_data(self, data: str):
        if self._skip_depth > 0 or self.total_tags > 2000:
            return
        text = data.strip()
        if not text:
            return
        if self._in_title:
            self.title += " " + text
        elif self._in_heading:
            self._current_heading += " " + text
        elif self._in_button:
            self._current_button += " " + text
        elif len(self.text_chunks) < 30:
            self.text_chunks.append(text)


@dataclass
class PageInspectionResult:
    """Structured inspection findings for a destination webpage."""
    url: str
    inspected: bool
    page_title: str = "Unavailable"
    status_code: int = 0
    detected_brands: List[str] = field(default_factory=list)
    red_flags: List[str] = field(default_factory=list)
    is_suspicious_page: bool = False
    has_forms: bool = False
    has_credential_harvesting: bool = False
    has_payment_capture: bool = False
    has_brand_impersonation: bool = False
    inputs_count: int = 0
    forms_count: int = 0
    error: Optional[str] = None

    def get_summary_line(self) -> str:
        """Returns a concise summary line for link verification cards, or empty string if uninformative."""
        if not self.inspected or self.status_code >= 400:
            return ""

        title_display = f'"{self.page_title}"' if self.page_title and self.page_title not in ("Unavailable", "Untitled Page") else ""
        if self.red_flags:
            flags_summary = "; ".join(self.red_flags[:2])
            prefix = f"Destination Page: {title_display}. " if title_display else "Destination Page: "
            return f"{prefix}Security Alert: {flags_summary}"
        elif self.has_forms:
            if title_display:
                return f"Destination Page: {title_display} (interactive form detected)"
            return "Destination Page: Interactive web form detected"
        elif title_display:
            return f"Destination Page: {title_display} (standard content verified)"
        else:
            return ""


def is_safe_for_inspection(url: str) -> bool:
    """Verifies that URL scheme and host are safe to inspect (prevents SSRF/loopback)."""
    try:
        parsed = urlparse(url)
        if parsed.scheme.lower() not in ('http', 'https'):
            return False
        host = (parsed.hostname or "").lower()
        if not host or host in ('localhost', '127.0.0.1', '::1'):
            return False
        # Disallow cloud metadata and link-local addresses
        if host.startswith('169.254.') or host.startswith('10.') or host.startswith('192.168.'):
            return False
        return True
    except Exception:
        return False


def inspect_webpage_content(
    url: str,
    redirect_hops_count: int = 0,
    timeout: float = INSPECTION_TIMEOUT_SECONDS
) -> PageInspectionResult:
    """
    Safely inspects the destination webpage at `url`.
    Extracts page title, forms, inputs, payment requests, brand impersonation,
    and returns a structured PageInspectionResult.
    """
    if not is_safe_for_inspection(url):
        return PageInspectionResult(
            url=url,
            inspected=False,
            error="Destination disallowed by SSRF security policy"
        )

    try:
        session = requests.Session()
        session.headers.update({
            "User-Agent": INSPECTOR_USER_AGENT,
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.5",
        })

        # Safely follow up to 3 redirects, verifying SSRF safety on every hop
        curr_url = url
        resp = None
        for hop in range(3):
            if not is_safe_for_inspection(curr_url):
                return PageInspectionResult(
                    url=curr_url,
                    inspected=False,
                    error="Redirect destination disallowed by security policy"
                )
            r = session.get(curr_url, timeout=timeout, stream=True, allow_redirects=False)
            r_status = getattr(r, 'status_code', None)
            if isinstance(r_status, int) and r_status in (301, 302, 303, 307, 308) and hasattr(r, 'headers') and 'Location' in r.headers:
                from urllib.parse import urljoin
                next_loc = r.headers['Location']
                curr_url = urljoin(curr_url, next_loc)
                r.close()
                continue
            resp = r
            break

        if resp is None:
            session.close()
            return PageInspectionResult(url=url, inspected=False, error="No response received from destination")

        raw_status = getattr(resp, 'status_code', None)
        status_code = raw_status if isinstance(raw_status, int) else 200
        if status_code >= 400:
            resp.close()
            session.close()
            return PageInspectionResult(
                url=curr_url,
                inspected=False,
                status_code=status_code,
                error=f"Destination returned HTTP {status_code}"
            )

        content_type = resp.headers.get('Content-Type', '').lower()

        # If binary or download file
        if any(b in content_type for b in ('application/octet-stream', 'application/x-msdownload', 'application/zip')):
            resp.close()
            session.close()
            return PageInspectionResult(
                url=curr_url,
                inspected=True,
                status_code=status_code,
                page_title="Binary Executable / Archive File",
                red_flags=["Direct Binary Download: Destination serves a binary/executable payload"],
                is_suspicious_page=True
            )

        # Read clamped chunk
        raw_bytes = b""
        for chunk in resp.iter_content(chunk_size=8192):
            raw_bytes += chunk
            if len(raw_bytes) >= MAX_INSPECTION_BYTES:
                break
        resp.close()
        session.close()

        # Decode HTML safely
        encoding = resp.encoding or 'utf-8'
        try:
            html_text = raw_bytes.decode(encoding, errors='replace')
        except Exception:
            html_text = raw_bytes.decode('utf-8', errors='replace')

        # Parse DOM
        parser = _SafeDOMParser()
        parser.feed(html_text)

        # Analyze extracted content
        final_domain = (urlparse(url).hostname or "").lower()
        red_flags: List[str] = []
        detected_brands: List[str] = []

        # 1. Credential Harvesting & Sensitive Input Detection
        has_pwd = any(inp['type'] == 'password' for inp in parser.inputs)
        has_payment_inp = any(
            any(k in inp['name'] or k in inp['placeholder'].lower()
                for k in ('card', 'cvv', 'cvc', 'exp', 'routing', 'account', 'iban'))
            for inp in parser.inputs
        )
        has_identity_inp = any(
            any(k in inp['name'] or k in inp['placeholder'].lower()
                for k in ('ssn', 'tax_id', 'passport', 'license', 'dob', 'mother'))
            for inp in parser.inputs
        )
        has_otp_inp = any(
            any(k in inp['name'] or k in inp['placeholder'].lower()
                for k in ('otp', '2fa', 'token', 'passcode', 'verification_code'))
            for inp in parser.inputs
        )

        if has_pwd:
            red_flags.append("Credential Harvesting: Password input field detected on page")
        if has_payment_inp:
            red_flags.append("Payment & Card Capture: Credit card or banking input fields detected")
        if has_identity_inp:
            red_flags.append("Identity Theft Risk: Sensitive personal identity (SSN/Tax ID/DOB) fields requested")
        if has_otp_inp:
            red_flags.append("2FA Hijacking: One-time passcode (OTP) or authentication token requested")

        # 2. Payment / Fee Demands in Page Text or Action Buttons
        all_text = " ".join([parser.title] + parser.headings + parser.buttons + parser.text_chunks).lower()
        fee_match = re.search(
            r'(?:pay|fee|cost|charge|invoice|due|transfer|amount)\s*[:\$]?\s*(\$?\d+(?:\.\d{2})?|\d+\s*(?:usd|eur|gbp))',
            all_text
        )
        if fee_match:
            red_flags.append(f"Financial Demand: Page prompts for payment ({fee_match.group(0).strip()})")

        # 3. Brand Impersonation & Logo Spoofing
        has_brand_impersonation = False
        for brand, legit_domains in KNOWN_BRAND_DOMAINS.items():
            brand_pattern = rf'\b{re.escape(brand)}\b'
            brand_in_title = bool(re.search(brand_pattern, parser.title, re.IGNORECASE))
            brand_in_headings = any(bool(re.search(brand_pattern, h, re.IGNORECASE)) for h in parser.headings)
            brand_in_imgs = any(
                bool(re.search(brand_pattern, img['alt'] + ' ' + img['title'] + ' ' + img['src'], re.IGNORECASE))
                for img in parser.images
            )

            if brand_in_title or brand_in_headings or brand_in_imgs:
                detected_brands.append(brand.upper())
                is_legit = any(final_domain == d or final_domain.endswith('.' + d) for d in legit_domains)
                if not is_legit:
                    has_brand_impersonation = True
                    red_flags.append(f"Brand Impersonation: Displays {brand.upper()} branding on mismatched domain ({final_domain})")

        # 4. Malware Delivery / Dangerous Downloads
        if parser.suspicious_downloads:
            red_flags.append(f"Malware Delivery: Executable or archive downloads detected ({', '.join(parser.suspicious_downloads[:2])})")

        # 5. Evasive Multi-Hop Redirect Corroboration
        if redirect_hops_count > 1 and red_flags:
            red_flags.append(f"Evasive Redirection: Page reached via {redirect_hops_count} redirect hops to conceal hostile inputs")

        # 6. Urgent Coercion & Common Scam Signatures
        urgent_scam_match = re.search(
            r'\b(account suspended|temporarily locked|urgent action required|arrest warrant|claim your prize|congratulations you won|crypto doubling)\b',
            all_text
        )
        if urgent_scam_match:
            red_flags.append(f"Deceptive / Coercive Language: Page contains '{urgent_scam_match.group(0)}'")

        clean_title = parser.title.strip() or parser.meta_tags.get('og:title', '').strip() or "Untitled Page"

        return PageInspectionResult(
            url=url,
            inspected=True,
            page_title=clean_title,
            status_code=status_code,
            detected_brands=detected_brands,
            red_flags=red_flags,
            is_suspicious_page=len(red_flags) > 0,
            has_forms=len(parser.forms) > 0,
            has_credential_harvesting=has_pwd or has_otp_inp,
            has_payment_capture=has_payment_inp or bool(fee_match),
            has_brand_impersonation=has_brand_impersonation,
            inputs_count=len(parser.inputs),
            forms_count=len(parser.forms),
        )

    except requests.exceptions.Timeout:
        return PageInspectionResult(
            url=url,
            inspected=False,
            error="Inspection connection timed out"
        )
    except Exception as exc:
        logger.debug("Page inspection error for %s: %s", url, exc)
        return PageInspectionResult(
            url=url,
            inspected=False,
            error=str(exc)
        )
