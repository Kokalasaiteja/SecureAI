import os
import secrets
import logging
import resend
from django.conf import settings
from django.core.mail import send_mail

logger = logging.getLogger(__name__)

# Initialize safely using the system environment
resend.api_key = os.environ.get("RESEND_API_KEY", "")

def generate_six_digit_otp():
    """Generates a cryptographically secure 6-digit numeric OTP."""
    return f"{secrets.SystemRandom().randint(100000, 999999)}"

def send_secure_otp_email(target_email, otp_code):
    """
    Dispatches a structured operational email via Resend over Port 443 HTTPS.
    Falls back gracefully to Gmail SMTP specifically when Resend rejects the recipient
    due to sandbox restrictions (unverified recipient with onboarding@resend.dev).
    """
    api_key = getattr(settings, 'RESEND_API_KEY', None) or os.environ.get("RESEND_API_KEY", "")
    sender = getattr(settings, 'RESEND_FROM_EMAIL', None) or os.environ.get("RESEND_FROM_EMAIL", "SecureAI Gateway <onboarding@resend.dev>")
    resend_err = None
    is_sandbox_error = False

    # 1. Attempt delivery via Resend API if API key is configured
    if api_key:
        try:
            resend.api_key = api_key
            params = {
                "from": sender,
                "to": [target_email],
                "subject": f"[{otp_code}] SecureAI Authorization Passcode",
                "html": f"""
                    <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 500px; margin: 0 auto; padding: 30px; border: 1px solid #e2e8f0; border-radius: 12px; background-color: #ffffff;">
                        <div style="text-align: center; margin-bottom: 25px;">
                            <span style="background: #e0e7ff; color: #4f46e5; padding: 8px 16px; border-radius: 20px; font-size: 13px; font-weight: 600; letter-spacing: 0.5px;">SECUREAI SECURITY ENGINE</span>
                        </div>
                        <h2 style="color: #0f172a; font-size: 22px; font-weight: 700; text-align: center; margin-top: 0;">Verification Required</h2>
                        <p style="color: #475569; font-size: 15px; line-height: 1.6; text-align: center;">A password reset was requested for your account. Use the one-time authentication passcode below to proceed:</p>
                        <div style="background: #f8fafc; border: 1px dashed #cbd5e1; border-radius: 8px; padding: 20px; text-align: center; margin: 25px 0;">
                            <span style="font-family: 'Courier New', Courier, monospace; font-size: 36px; font-weight: 800; color: #1e1b4b; letter-spacing: 6px; display: inline-block; padding-left: 6px;">{otp_code}</span>
                        </div>
                        <p style="color: #64748b; font-size: 12px; text-align: center; margin-bottom: 0; line-height: 1.5;">
                            This passcode is temporary and expires dynamically in 5 minutes.<br/>
                            If you did not initiate this request, please audit your dashboard credentials immediately.
                        </p>
                    </div>
                """
            }
            response = resend.Emails.send(params)
            logger.info(f"OTP email systematically fired via Resend. Registry ID: {response.get('id')}")
            return True, None
        except Exception as error:
            resend_err = str(error)
            logger.error(f"Resend transaction failed for {target_email}: {resend_err}")

            lower_err = resend_err.lower()
            if any(term in lower_err for term in [
                "only send testing emails",
                "testing emails to your own email address",
                "to send to other domains",
                "verify your domain",
                "resend.com/domains",
                "domain is not verified",
                "validation_error",
            ]):
                is_sandbox_error = True
    else:
        # If RESEND_API_KEY is not configured at all, treat as requiring direct SMTP fallback
        is_sandbox_error = True

    # 2. If Resend rejected recipient specifically due to sandbox restrictions (or no Resend API key), attempt Gmail SMTP
    if is_sandbox_error:
        host_user = getattr(settings, 'EMAIL_HOST_USER', None) or os.environ.get('EMAIL_HOST_USER', '')
        host_pass = getattr(settings, 'EMAIL_HOST_PASSWORD', None) or os.environ.get('EMAIL_HOST_PASSWORD', '')

        if host_user and host_pass and str(host_pass).strip() not in ('', 'None'):
            try:
                subject = f"[{otp_code}] SecureAI Authorization Passcode"
                plain_msg = f"Your SecureAI verification code is: {otp_code}. Valid for 5 minutes."
                send_mail(
                    subject=subject,
                    message=plain_msg,
                    from_email=host_user,
                    recipient_list=[target_email],
                    fail_silently=False,
                )
                logger.info(f"OTP email successfully sent via Gmail SMTP fallback to {target_email}")
                return True, None
            except Exception as smtp_err:
                logger.error(f"Gmail SMTP fallback failed for {target_email}: {smtp_err}")
                return False, "Failed to deliver verification email via Resend and Gmail SMTP. Please verify Render email configuration."
        else:
            return False, (
                "Email delivery restricted: Resend free tier only delivers to the owner's email address. "
                "To deliver to all users, configure EMAIL_HOST_PASSWORD (Google App Password) on Render or verify a domain in Resend."
            )

    # 3. Handle non-sandbox Resend errors appropriately without leaking credentials
    if resend_err:
        lower_err = resend_err.lower()
        if "api_key" in lower_err or "unauthorized" in lower_err or "401" in lower_err:
            return False, "Email service authentication failed. Check RESEND_API_KEY on Render."
        elif "rate limit" in lower_err or "429" in lower_err:
            return False, "Email service rate limit reached. Please wait a moment and try again."
        else:
            return False, "Email delivery failed due to network error. Please try again."

    return False, "Failed to send email. Check Render Environment Variables (RESEND_API_KEY or EMAIL_HOST_PASSWORD)."


def is_safe_user_image_path(image_name):
    """
    Validates that the image file path is strictly within the user_images/ directory
    and does not point to system assets, parent directories, or shared files.
    """
    if not image_name:
        return False

    norm = os.path.normpath(str(image_name)).replace('\\', '/')
    # Must not traverse upwards or start with absolute root
    if '..' in norm or norm.startswith('/'):
        return False

    # Must be inside user_images directory
    if not (norm.startswith('user_images/') or norm == 'user_images'):
        return False

    # Must not be a shared system file or model binary
    filename = os.path.basename(norm).lower()
    protected_files = {
        'app-release.apk', 'app-arm64-v8a-release.apk', 'app-armeabi-v7a-release.apk',
        'app-x86_64-release.apk', 'behavior_anomaly_dataset.csv', 'favicon.png',
        'favicon.ico', 'user_avatar.jpg', 'random_forest.pkl',
        'logistic_regression.pkl', 'xgboost.pkl'
    }
    if filename in protected_files or filename.endswith('.apk') or filename.endswith('.pkl'):
        return False

    return True


def delete_user_account(user, current_request=None, otp_storage_ref=None):
    """
    Comprehensively and securely deletes a user account and associated personal data:
    1. Validates the user record.
    2. Atomically deletes the database row in a transaction (cascading/protecting via Django on_delete).
    3. Safely removes the physical profile picture from disk and storage if not shared by another user.
    4. Purges all active sessions for this user from django_session.
    5. Cleans up in-memory OTP dictionaries and session challenges.
    6. Flushes the current session if requested by the authenticated user.

    Returns:
        tuple (bool success, str message)
    """
    from pathlib import Path
    from django.db import transaction, DatabaseError
    from django.db.models import ProtectedError
    from django.core.files.storage import default_storage
    from django.contrib.sessions.models import Session
    from django.conf import settings
    from .models import RegisteredUser

    if not user or not user.pk:
        return False, "Invalid user record provided for deletion."

    user_id = user.id
    user_email = (user.email or '').strip()
    image_name = user.image.name if user.image else None

    # Check whether any other user in the database references the same image file
    other_users_share_image = False
    if image_name:
        other_users_share_image = RegisteredUser.objects.exclude(id=user_id).filter(image=image_name).exists()

    # Step 1: Database deletion within an atomic transaction
    try:
        with transaction.atomic():
            user.delete()
    except ProtectedError as pe:
        logger.error(f"Cannot delete user {user_id}: protected related records exist ({pe})")
        return False, "Account cannot be deleted because protected related records exist."
    except DatabaseError as dbe:
        logger.error(f"Database error deleting user {user_id}: {dbe}")
        return False, "Database error occurred while deleting account."
    except Exception as exc:
        logger.error(f"Unexpected error deleting user {user_id}: {exc}")
        return False, f"Deletion failed: {str(exc)}"

    # Step 2: Physical file storage cleanup
    if image_name and not other_users_share_image and is_safe_user_image_path(image_name):
        try:
            # Delete via Django default storage
            if default_storage.exists(image_name):
                default_storage.delete(image_name)

            # Also verify and remove disk file if materialized by smart_media_serve
            disk_path = Path(settings.MEDIA_ROOT) / image_name
            if disk_path.exists() and disk_path.is_file():
                try:
                    disk_path.unlink()
                except OSError as os_err:
                    logger.warning(f"Could not remove local file {disk_path}: {os_err}")
        except Exception as storage_err:
            logger.warning(f"File storage cleanup warning for {image_name}: {storage_err}")

    # Step 3: Purge in-memory OTP records
    if otp_storage_ref is not None and isinstance(otp_storage_ref, dict):
        if user_email:
            otp_storage_ref.pop(user_email, None)

    # Step 4: Invalidate all active sessions for this user in django_session
    try:
        for s in Session.objects.all():
            try:
                data = s.get_decoded()
                if data.get('user_id') == user_id or (user_email and data.get('reset_email') == user_email):
                    s.delete()
            except Exception:
                pass
    except Exception as sess_err:
        logger.warning(f"Session cleanup error for user {user_id}: {sess_err}")

    # Step 5: Flush current session if the request belongs to the deleted user
    if current_request is not None and hasattr(current_request, 'session'):
        try:
            current_request.session.flush()
        except Exception:
            pass

    return True, "Account successfully deleted."


import re
from urllib.parse import urlparse

def extract_urls(text: str) -> list:
    """
    Extracts all hyperlinks, domains, IP-based URLs, and shortlinks from text.
    Returns a deduplicated list of clean URL strings.
    """
    if not text:
        return []
    pattern = (
        r'(?:https?://[^\s<>\x22\x27()]+)|'
        r'(?:www\.[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(?:/[^\s<>\x22\x27()]*)?)|'
        r'(?:(?:bit\.ly|tinyurl\.com|t\.co|goo\.gl|is\.gd|cutt\.ly|ow\.ly)/[^\s<>\x22\x27()]+)|'
        r'(?:[a-zA-Z0-9.-]+\.(?:com|org|net|edu|gov|io|co|in|xyz|top|live|site|online|tech|app|dev|me|info|biz)/[^\s<>\x22\x27()]+)|'
        r'(?:(?:https?://)?\d{1,3}(?:\.\d{1,3}){3}(?::\d+)?(?:/[^\s<>\x22\x27()]*)?)'
    )
    raw_matches = re.findall(pattern, text, re.IGNORECASE)
    cleaned = []
    for m in raw_matches:
        u = re.sub(r'[\.,;!?\)\]\}>]+$', '', m.strip())
        if u and u not in cleaned:
            cleaned.append(u)
    return cleaned


def evaluate_url_heuristics(url: str) -> tuple:
    """
    Inspects URL structure for malicious or high-risk indicators:
    1. Raw IP addresses
    2. URL shorteners masking destination
    3. High-risk abusive TLDs (.xyz, .top, .cam, .click, etc.)
    4. Credential-harvesting keywords combined with suspicious subdomains
    5. Brand impersonation / spoofing
    Returns (is_suspicious: bool, reason: str).
    """
    norm = (url or '').lower().strip()
    if not norm:
        return False, "Empty URL"

    # 1. IP address host
    if re.search(r'^(?:https?://)?\d{1,3}(?:\.\d{1,3}){3}', norm):
        return True, "Uses a raw numerical IP address instead of an authenticated domain name."

    # 2. Obfuscated URL shortener
    shorteners = ['bit.ly', 'tinyurl.com', 't.co', 'goo.gl', 'is.gd', 'cutt.ly', 'ow.ly']
    if any(s in norm for s in shorteners):
        return True, "Uses an obfuscated URL shortener masking the true destination."

    # 3. Risky TLDs commonly abused in smishing and phishing campaigns
    risky_tlds = ['.xyz', '.top', '.click', '.cam', '.work', '.loan', '.zip', '.party', '.gq', '.cf', '.tk', '.ml', '.buzz']
    for tld in risky_tlds:
        if tld in norm:
            if any(k in norm for k in ['login', 'verify', 'update', 'banking', 'secure', 'account', 'otp', 'wallet', 'confirm', 'auth', 'signin']):
                return True, f"Combines high-risk TLD '{tld}' with sensitive account action keywords."
            return True, f"Uses high-risk TLD '{tld}' commonly abused in smishing and phishing campaigns."

    # 4. Brand spoofing / lookalike subdomains
    spoofed_brands = ['paypal', 'apple', 'google', 'amazon', 'netflix', 'microsoft', 'chase', 'wellsfargo', 'bankofamerica', 'sbi', 'hdfc']
    for b in spoofed_brands:
        if b in norm and not (norm.endswith(f'.{b}.com') or f'.{b}.com/' in norm or norm.startswith(f'https://{b}.com') or norm.startswith(f'http://{b}.com')):
            if any(k in norm for k in ['login', 'verify', 'secure', 'account', 'update', 'portal', 'signin', 'auth']):
                return True, f"Deceptive brand spoofing targeting {b.capitalize()}."

    return False, "Standard domain structure."


def verify_all_links_in_content(content_text: str, classify_url_func=None) -> dict:
    """
    Extracts and comprehensively analyzes all links found inside an SMS or email message.
    Cross-checks heuristic indicators and optional AI threat classification.
    """
    urls = extract_urls(content_text)
    if not urls:
        return {
            'has_links': False,
            'urls': [],
            'is_unsafe': False,
            'first_unsafe_url': None,
            'first_unsafe_reason': None,
            'summary': "No external links or URLs detected in message.",
            'details': []
        }

    details = []
    any_unsafe = False
    first_unsafe_url = None
    first_unsafe_reason = None

    # Inspect up to 3 unique links to keep latency low
    for u in urls[:3]:
        is_suspicious_heuristic, heuristic_reason = evaluate_url_heuristics(u)
        
        ai_verdict = None
        ai_reason = None
        if classify_url_func:
            try:
                raw_ai = classify_url_func(u)
                if raw_ai:
                    lower_ai = raw_ai.lower()
                    if 'phishing' in lower_ai:
                        ai_verdict = 'Phishing'
                    elif 'malicious' in lower_ai:
                        ai_verdict = 'Malicious'
                    elif 'safe' in lower_ai:
                        ai_verdict = 'Safe'
                    elif 'suspicious' in lower_ai:
                        ai_verdict = 'Suspicious'

                    ai_reason = raw_ai.split(':', 1)[-1].strip() if ':' in raw_ai else raw_ai.strip()
            except Exception as e:
                import logging
                logging.getLogger(__name__).warning(f"AI URL verification error for {u}: {e}")

        final_verdict = ai_verdict or ('Suspicious' if is_suspicious_heuristic else 'Safe')
        if is_suspicious_heuristic and final_verdict == 'Safe':
            final_verdict = 'Suspicious'
            final_reason = f"{heuristic_reason} (AI note: {ai_reason or 'unverified'})"
        else:
            final_reason = ai_reason or heuristic_reason

        is_unsafe = final_verdict in ('Phishing', 'Malicious', 'Suspicious')
        item = {
            'url': u,
            'verdict': final_verdict,
            'reason': final_reason,
            'is_unsafe': is_unsafe
        }
        details.append(item)

        if is_unsafe and not any_unsafe:
            any_unsafe = True
            first_unsafe_url = u
            first_unsafe_reason = final_reason

    if any_unsafe:
        summary = f"Flagged unsafe link: '{first_unsafe_url}' ({first_unsafe_reason})"
    else:
        summary = f"Inspected link(s) verified as safe/legitimate: {', '.join(urls[:3])}"

    return {
        'has_links': True,
        'urls': urls,
        'is_unsafe': any_unsafe,
        'first_unsafe_url': first_unsafe_url,
        'first_unsafe_reason': first_unsafe_reason,
        'summary': summary,
        'details': details
    }

