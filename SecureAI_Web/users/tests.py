import time
import secrets
import hashlib
from unittest.mock import patch, MagicMock
from django.test import TestCase, Client
from django.contrib.auth.hashers import make_password, check_password

# Fix Python 3.14 upstream Django Context.__copy__ bug
from django.template import context as django_context
def _patched_copy(self):
    duplicate = self.__class__.__new__(self.__class__)
    duplicate.dicts = self.dicts[:]
    return duplicate
django_context.BaseContext.__copy__ = _patched_copy

from users.models import RegisteredUser
from users.utils import generate_six_digit_otp, send_secure_otp_email
from users.views import otp_storage, OTP_EXPIRY_SECONDS, OTP_RATE_LIMIT_SECONDS, OTP_MAX_ATTEMPTS, get_otp_hmac

class ForgotPasswordOTPFlowTests(TestCase):
    def setUp(self):
        otp_storage.clear()
        self.client = Client()
        self.user = RegisteredUser.objects.create(
            name="testuser",
            email="testuser@example.com",
            mobile="9876543210",
            password=make_password("OldPassword123"),
            is_active=True
        )

    def tearDown(self):
        otp_storage.clear()

    # 1. Resend Success
    @patch('users.utils.resend.Emails.send')
    def test_resend_success(self, mock_resend_send):
        mock_resend_send.return_value = {'id': 'msg_test_12345'}
        with self.settings(RESEND_API_KEY='re_test_key_valid'):
            success, err = send_secure_otp_email("testuser@example.com", "123456")
            self.assertTrue(success)
            self.assertIsNone(err)
            mock_resend_send.assert_called_once()

    # 2. Resend Sandbox Rejection followed by successful Gmail SMTP fallback
    @patch('users.utils.send_mail')
    @patch('users.utils.resend.Emails.send')
    def test_resend_sandbox_rejection_followed_by_smtp_fallback(self, mock_resend_send, mock_send_mail):
        mock_resend_send.side_effect = Exception("You can only send testing emails to your own email address (owner@example.com).")
        mock_send_mail.return_value = 1
        with self.settings(
            RESEND_API_KEY='re_test_key',
            EMAIL_HOST_USER='myemail@gmail.com',
            EMAIL_HOST_PASSWORD='app_password_1234'
        ):
            success, err = send_secure_otp_email("friend@example.com", "654321")
            self.assertTrue(success)
            self.assertIsNone(err)
            mock_send_mail.assert_called_once()
            args, kwargs = mock_send_mail.call_args
            self.assertEqual(kwargs['recipient_list'], ['friend@example.com'])

    # 3. Resend Failure followed by SMTP failure
    @patch('users.utils.send_mail')
    @patch('users.utils.resend.Emails.send')
    def test_resend_failure_followed_by_smtp_failure(self, mock_resend_send, mock_send_mail):
        mock_resend_send.side_effect = Exception("You can only send testing emails to your own email address.")
        mock_send_mail.side_effect = Exception("SMTP server disconnected.")
        with self.settings(
            RESEND_API_KEY='re_test_key',
            EMAIL_HOST_USER='myemail@gmail.com',
            EMAIL_HOST_PASSWORD='app_password_1234'
        ):
            success, err = send_secure_otp_email("friend@example.com", "654321")
            self.assertFalse(success)
            self.assertIn("Failed to deliver", err)

    # 4. Invalid API Key (non-sandbox error should NOT trigger SMTP inappropriately)
    @patch('users.utils.send_mail')
    @patch('users.utils.resend.Emails.send')
    def test_invalid_api_key_no_smtp_fallback(self, mock_resend_send, mock_send_mail):
        mock_resend_send.side_effect = Exception("API_KEY is invalid. 401 Unauthorized.")
        with self.settings(
            RESEND_API_KEY='invalid_key',
            EMAIL_HOST_USER='myemail@gmail.com',
            EMAIL_HOST_PASSWORD='app_password_1234'
        ):
            success, err = send_secure_otp_email("test@example.com", "123456")
            self.assertFalse(success)
            self.assertIn("authentication failed", err.lower())
            mock_send_mail.assert_not_called()

    # 5. Invalid or Expired OTP
    @patch('users.views.send_otp')
    def test_invalid_and_expired_otp(self, mock_send_otp):
        # Manually seed OTP
        salt = secrets.token_hex(16)
        otp_hash = hashlib.sha256(f"{salt}:123456".encode('utf-8')).hexdigest()
        otp_storage['testuser@example.com'] = {
            'salt': salt,
            'otp_hash': otp_hash,
            'created_at': time.time(),
            'attempts': 0,
            'verified': False,
            'verified_at': None
        }

        # Step A: Wrong OTP
        wrong_resp = self.client.post('/verify-otp/', {'email': 'testuser@example.com', 'otp': '000000'}, HTTP_ACCEPT='application/json')
        self.assertEqual(wrong_resp.status_code, 400)
        self.assertIn("Invalid OTP", wrong_resp.json()['message'])

        # Step B: Expire OTP by tampering created_at
        otp_storage['testuser@example.com']['created_at'] = time.time() - (OTP_EXPIRY_SECONDS + 10)
        exp_resp = self.client.post('/verify-otp/', {'email': 'testuser@example.com', 'otp': '123456'}, HTTP_ACCEPT='application/json')
        self.assertEqual(exp_resp.status_code, 400)
        self.assertIn("expired", exp_resp.json()['message'].lower())

    # 6. OTP Reuse Prevention
    def test_otp_reuse_prevented(self):
        salt = secrets.token_hex(16)
        otp_hash = get_otp_hmac(salt, 'testuser@example.com', '888999')
        otp_storage['testuser@example.com'] = {
            'salt': salt,
            'otp_hash': otp_hash,
            'otp_hmac': otp_hash,
            'created_at': time.time(),
            'attempts': 0,
            'verified': False,
            'verified_at': None
        }

        # First verification succeeds
        resp1 = self.client.post('/verify-otp/', {'email': 'testuser@example.com', 'otp': '888999'}, HTTP_ACCEPT='application/json')
        self.assertEqual(resp1.status_code, 200)
        self.assertTrue(resp1.json()['success'])

        # Second verification with same OTP is blocked (otp_hash popped)
        resp2 = self.client.post('/verify-otp/', {'email': 'testuser@example.com', 'otp': '888999'}, HTTP_ACCEPT='application/json')
        self.assertEqual(resp2.status_code, 400)

    # 7. Too many OTP attempts
    def test_too_many_otp_attempts(self):
        salt = secrets.token_hex(16)
        otp_hash = get_otp_hmac(salt, 'testuser@example.com', '999888')
        otp_storage['testuser@example.com'] = {
            'salt': salt,
            'otp_hash': otp_hash,
            'otp_hmac': otp_hash,
            'created_at': time.time(),
            'attempts': 0,
            'verified': False,
            'verified_at': None
        }

        for i in range(OTP_MAX_ATTEMPTS):
            resp = self.client.post('/verify-otp/', {'email': 'testuser@example.com', 'otp': f'11111{i}'}, HTTP_ACCEPT='application/json')

        self.assertEqual(resp.status_code, 400)
        self.assertIn("Maximum attempts reached", resp.json()['message'])
        self.assertNotIn('testuser@example.com', otp_storage)

    # 8. OTP Resend Cooldown
    @patch('users.utils.send_secure_otp_email')
    def test_otp_resend_cooldown(self, mock_send_email):
        mock_send_email.return_value = (True, None)
        resp1 = self.client.post('/forgot-password/', {'email': 'testuser@example.com'}, HTTP_ACCEPT='application/json')
        self.assertEqual(resp1.status_code, 200)

        # Immediate second request triggers 429 cooldown
        resp2 = self.client.post('/forgot-password/', {'email': 'testuser@example.com'}, HTTP_ACCEPT='application/json')
        self.assertEqual(resp2.status_code, 429)
        self.assertIn("Please wait", resp2.json()['message'])

    # 9. Successful Password Reset and Login
    def test_successful_password_reset_and_login(self):
        # Manually simulate successful OTP verification with reset_token
        test_token = secrets.token_urlsafe(32)
        otp_storage['testuser@example.com'] = {
            'verified': True,
            'verified_at': time.time(),
            'reset_token': test_token,
        }

        # Reset password providing the issued reset_token
        r_resp = self.client.post('/reset-password/', {
            'email': 'testuser@example.com',
            'new_password': 'BrandNewPassword789',
            'confirm_password': 'BrandNewPassword789',
            'reset_token': test_token,
        }, HTTP_ACCEPT='application/json')
        self.assertEqual(r_resp.status_code, 200)
        self.assertTrue(r_resp.json()['success'])

        # Verify DB updated
        self.user.refresh_from_db()
        self.assertTrue(check_password('BrandNewPassword789', self.user.password))
        self.assertFalse(check_password('OldPassword123', self.user.password))

        # Login with old password fails
        login_fail = self.client.post('/user-login/', {'name': 'testuser', 'password': 'OldPassword123'}, HTTP_ACCEPT='application/json')
        self.assertFalse(login_fail.json()['success'])

        # Login with new password succeeds
        login_ok = self.client.post('/user-login/', {'name': 'testuser', 'password': 'BrandNewPassword789'}, HTTP_ACCEPT='application/json')
        self.assertTrue(login_ok.json()['success'])

    # 10. Unauthorized Reset without OTP verification
    def test_unauthorized_reset_without_otp(self):
        resp = self.client.post('/reset-password/', {
            'email': 'testuser@example.com',
            'new_password': 'HackerPassword123',
            'confirm_password': 'HackerPassword123'
        }, HTTP_ACCEPT='application/json')
        self.assertEqual(resp.status_code, 403)
        self.assertIn("Unauthorized", resp.json()['message'])

    # 11. Password Mismatch on Reset
    def test_password_mismatch_on_reset(self):
        test_token = secrets.token_urlsafe(32)
        otp_storage['testuser@example.com'] = {
            'verified': True,
            'verified_at': time.time(),
            'reset_token': test_token,
        }

        resp = self.client.post('/reset-password/', {
            'email': 'testuser@example.com',
            'new_password': 'PasswordA',
            'confirm_password': 'PasswordB',
            'reset_token': test_token,
        }, HTTP_ACCEPT='application/json')
        self.assertEqual(resp.status_code, 400)
        self.assertIn("do not match", resp.json()['message'])

    # 12. URL Extraction & Link Safety Heuristics
    def test_url_extraction_and_heuristics(self):
        from users.utils import extract_urls, evaluate_url_heuristics, verify_all_links_in_content
        
        msg1 = "Hello, check http://bit.ly/bank-verify now"
        urls = extract_urls(msg1)
        self.assertIn("http://bit.ly/bank-verify", urls)
        
        is_suspicious, reason = evaluate_url_heuristics("http://bit.ly/bank-verify")
        self.assertTrue(is_suspicious)
        self.assertIn("shortener", reason.lower())

        is_suspicious_ip, reason_ip = evaluate_url_heuristics("http://192.168.1.1/login")
        self.assertTrue(is_suspicious_ip)
        self.assertIn("numerical ip address", reason_ip.lower())

        report = verify_all_links_in_content(msg1)
        self.assertTrue(report['has_links'])
        self.assertTrue(report['is_unsafe'])

    # 13. SMS with Unsafe Link is Classified as Spam
    def test_sms_with_unsafe_link_classified_as_spam(self):
        session = self.client.session
        session['user_id'] = self.user.id
        session['user_email'] = self.user.email
        session.save()

        resp = self.client.post('/detect_spam/', {
            'message': 'Hi there! Please click http://bit.ly/free-gift to claim'
        }, HTTP_ACCEPT='application/json')
        
        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        self.assertEqual(data['result'], 'Spam')
        self.assertIn('suspicious or unsafe link', data['explanation'])
        self.assertIn('bit.ly', data['explanation'])

    # 14. Email with Unsafe Link is Classified as Phishing
    def test_email_with_unsafe_link_classified_as_phishing(self):
        session = self.client.session
        session['user_id'] = self.user.id
        session['user_email'] = self.user.email
        session.save()

        resp = self.client.post('/email-phishing/', {
            'email_text': 'Your account security notice. Verify at http://192.168.1.50/auth'
        }, HTTP_ACCEPT='application/json')

        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        self.assertEqual(data['result'], 'Phishing')
        self.assertTrue(data['is_phishing'])
        self.assertIn('Link Security Audit', data['explanation'])

    # 15. Direct API Password Reset without valid reset_token is blocked
    def test_direct_api_bypass_without_token_blocked(self):
        # Even if user was somehow verified, missing or wrong reset_token returns 403
        otp_storage['testuser@example.com'] = {
            'verified': True,
            'verified_at': time.time(),
            'reset_token': 'correct_token_123',
        }

        # Missing token
        resp1 = self.client.post('/reset-password/', {
            'email': 'testuser@example.com',
            'new_password': 'AttackerPassword',
            'confirm_password': 'AttackerPassword',
        }, HTTP_ACCEPT='application/json')
        self.assertEqual(resp1.status_code, 403)

        # Forged wrong token
        resp2 = self.client.post('/reset-password/', {
            'email': 'testuser@example.com',
            'new_password': 'AttackerPassword',
            'confirm_password': 'AttackerPassword',
            'reset_token': 'wrong_forged_token',
        }, HTTP_ACCEPT='application/json')
        self.assertEqual(resp2.status_code, 403)
    # 16. Brevo HTTPS Fallback on Resend Sandbox Rejection
    @patch('requests.post')
    @patch('users.utils.resend.Emails.send')
    def test_brevo_https_fallback_on_resend_sandbox_rejection(self, mock_resend_send, mock_requests_post):
        mock_resend_send.side_effect = Exception("You can only send testing emails to your own email address.")
        mock_response = MagicMock()
        mock_response.status_code = 201
        mock_response.json.return_value = {'messageId': '<test-msg-id-12345@smtp-relay.mailin.fr>'}
        mock_requests_post.return_value = mock_response

        with self.settings(
            RESEND_API_KEY='re_sandbox_key',
            BREVO_API_KEY='xkeysib-test-key-12345',
            BREVO_SENDER_EMAIL='verified-sender@example.com'
        ):
            success, err = send_secure_otp_email("external-user@example.com", "789123")
            self.assertTrue(success)
            self.assertIsNone(err)
            mock_requests_post.assert_called_once()
            call_kwargs = mock_requests_post.call_args[1]
            self.assertEqual(call_kwargs['json']['sender']['email'], 'verified-sender@example.com')
            self.assertEqual(call_kwargs['json']['to'][0]['email'], 'external-user@example.com')

    # 17. OTP HMAC fails securely if SECRET_KEY is missing or empty
    def test_get_otp_hmac_fails_without_secret_key(self):
        with self.settings(SECRET_KEY=''):
            with self.assertRaises(RuntimeError) as ctx:
                get_otp_hmac(secrets.token_hex(16), "test@example.com", "123456")
            self.assertIn("SECRET_KEY is missing", str(ctx.exception))

