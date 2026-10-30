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
from users.views import otp_storage, OTP_EXPIRY_SECONDS, OTP_RATE_LIMIT_SECONDS, OTP_MAX_ATTEMPTS

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
        otp_hash = hashlib.sha256(f"{salt}:888999".encode('utf-8')).hexdigest()
        otp_storage['testuser@example.com'] = {
            'salt': salt,
            'otp_hash': otp_hash,
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
        otp_hash = hashlib.sha256(f"{salt}:999888".encode('utf-8')).hexdigest()
        otp_storage['testuser@example.com'] = {
            'salt': salt,
            'otp_hash': otp_hash,
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

    # 9. Successful Password Reset & 10. Login with new password
    def test_successful_password_reset_and_login(self):
        # Manually simulate successful OTP verification
        otp_storage['testuser@example.com'] = {
            'verified': True,
            'verified_at': time.time()
        }

        # Reset password
        r_resp = self.client.post('/reset-password/', {
            'email': 'testuser@example.com',
            'new_password': 'BrandNewPassword789',
            'confirm_password': 'BrandNewPassword789'
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

    # 11. Unauthorized Reset without OTP verification
    def test_unauthorized_reset_without_otp(self):
        resp = self.client.post('/reset-password/', {
            'email': 'testuser@example.com',
            'new_password': 'HackerPassword123',
            'confirm_password': 'HackerPassword123'
        }, HTTP_ACCEPT='application/json')
        self.assertEqual(resp.status_code, 403)
        self.assertIn("Unauthorized", resp.json()['message'])

    # 12. Password Mismatch on Reset
    def test_password_mismatch_on_reset(self):
        otp_storage['testuser@example.com'] = {
            'verified': True,
            'verified_at': time.time()
        }

        resp = self.client.post('/reset-password/', {
            'email': 'testuser@example.com',
            'new_password': 'PasswordA',
            'confirm_password': 'PasswordB'
        }, HTTP_ACCEPT='application/json')
        self.assertEqual(resp.status_code, 400)
        self.assertIn("do not match", resp.json()['message'])
