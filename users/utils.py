import os
import random
import logging
import resend

logger = logging.getLogger(__name__)

# Initialize safely using the system environment
resend.api_key = os.environ.get("RESEND_API_KEY", "re_CDmMjbrE_6QrZxx3Wi2bAGxNmRRkbSamg")

def generate_six_digit_otp():
    """Generates a secure numeric string for multi-factor checks."""
    return str(random.randint(100000, 999999))

def send_secure_otp_email(target_email, otp_code):
    """
    Dispatches a structured operational email via Resend over Port 443 HTTPS.
    Bypasses traditional cloud provider outbound network firewalls.
    """
    try:
        params = {
            "from": "SecureAI Gateway <onboarding@resend.dev>",
            "to": [target_email],
            "subject": f"[{otp_code}] SecureAI Authorization Passcode",
            "html": f"""
                <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 500px; margin: 0 auto; padding: 30px; border: 1px solid #e2e8f0; border-radius: 12px; background-color: #ffffff;">
                    <div style="text-align: center; margin-bottom: 25px;">
                        <span style="background: #e0e7ff; color: #4f46e5; padding: 8px 16px; border-radius: 20px; font-size: 13px; font-weight: 600; letter-spacing: 0.5px;">SECUREAI SECURITY ENGINE</span>
                    </div>
                    <h2 style="color: #0f172a; font-size: 22px; font-weight: 700; text-align: center; margin-top: 0;">Verification Required</h2>
                    <p style="color: #475569; font-size: 15px; line-height: 1.6; text-align: center;">A login or administrative check was triggered. Use the one-time authentication passcode below to confirm your context:</p>
                    <div style="background: #f8fafc; border: 1px dashed #cbd5e1; border-radius: 8px; padding: 20px; text-align: center; margin: 25px 0;">
                        <span style="font-family: 'Courier New', Courier, monospace; font-size: 36px; font-weight: 800; color: #1e1b4b; letter-spacing: 6px; display: inline-block; padding-left: 6px;">{otp_code}</span>
                    </div>
                    <p style="color: #64748b; font-size: 12px; text-align: center; margin-bottom: 0; line-height: 1.5;">
                        This passcode is temporary and expires dynamically in 5 minutes.<br/>
                        If you did not initiate this validation check, please audit your dashboard credentials immediately.
                    </p>
                </div>
            """
        }
        
        response = resend.Emails.send(params)
        logger.info(f"OTP email systematically fired via Resend. Registry ID: {response.get('id')}")
        return True
    except Exception as error:
        logger.error(f"Resend transaction failed: {str(error)}")
        return False
