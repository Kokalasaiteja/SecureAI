import os
import shutil
import sys
from pathlib import Path
from unittest.mock import patch
from importlib import import_module

from django.test import TestCase, Client, override_settings
from django.urls import reverse
from django.core.files.uploadedfile import SimpleUploadedFile
from django.core.files.storage import default_storage
from django.contrib.sessions.models import Session
from django.db import DatabaseError
from django.conf import settings
from django.template.context import BaseContext

# Compatibility shim for Python 3.14 + Django 5.0 test context copy
if sys.version_info >= (3, 14):
    def _safe_context_copy(self):
        duplicate = self.__class__.__new__(self.__class__)
        duplicate.__dict__.update(self.__dict__)
        duplicate.dicts = self.dicts[:]
        return duplicate
    BaseContext.__copy__ = _safe_context_copy

from users.models import RegisteredUser
from users.views import otp_storage
from users.utils import delete_user_account, is_safe_user_image_path

TEST_MEDIA_ROOT = os.path.join(os.path.dirname(__file__), 'test_media')

@override_settings(MEDIA_ROOT=TEST_MEDIA_ROOT)
class SecureAccountDeletionTests(TestCase):
    def setUp(self):
        self.client = Client()
        os.makedirs(os.path.join(TEST_MEDIA_ROOT, 'user_images'), exist_ok=True)

        # Create dummy image bytes (valid 1x1 GIF)
        self.dummy_image_bytes = (
            b'\x47\x49\x46\x38\x39\x61\x01\x00\x01\x00\x80\x00\x00\xff\xff\xff'
            b'\x00\x00\x00\x21\xf9\x04\x01\x00\x00\x00\x00\x2c\x00\x00\x00\x00'
            b'\x01\x00\x01\x00\x00\x02\x02\x44\x01\x00\x3b'
        )

        # Create primary test user
        uploaded_image = SimpleUploadedFile(
            name='test_avatar.gif',
            content=self.dummy_image_bytes,
            content_type='image/gif'
        )
        self.user = RegisteredUser.objects.create(
            name='alice_test',
            email='alice@example.com',
            mobile='9876543210',
            password='SecretPassword123!',
            image=uploaded_image,
            image_base64='data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7',
            is_active=True
        )

        # Create secondary test user (for tampering / isolation tests)
        uploaded_image2 = SimpleUploadedFile(
            name='bob_avatar.gif',
            content=self.dummy_image_bytes,
            content_type='image/gif'
        )
        self.user2 = RegisteredUser.objects.create(
            name='bob_test',
            email='bob@example.com',
            mobile='9123456780',
            password='BobPassword456!',
            image=uploaded_image2,
            image_base64='data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7',
            is_active=True
        )

    def tearDown(self):
        otp_storage.clear()
        if os.path.exists(TEST_MEDIA_ROOT):
            shutil.rmtree(TEST_MEDIA_ROOT, ignore_errors=True)

    def _login_user(self, user):
        session = self.client.session
        session['user_id'] = user.id
        session['user_name'] = user.name
        session['user_image'] = user.image.url if user.image else ''
        session['login_time'] = '10:00:00 AM'
        session.save()

    def _login_admin(self):
        session = self.client.session
        session['is_admin'] = True
        session.save()

    # --- 1. User Self-Deletion with Authentication and Confirmation ---

    def test_user_can_delete_own_account_with_correct_password(self):
        """Authenticated user successfully deletes their own account when providing correct password."""
        self._login_user(self.user)
        user_id = self.user.id
        image_name = self.user.image.name

        # Ensure image file exists on storage
        self.assertTrue(default_storage.exists(image_name))

        # Perform deletion request
        response = self.client.post(reverse('delete_account'), {'password': 'SecretPassword123!'})
        self.assertEqual(response.status_code, 302)
        self.assertEqual(response.url, reverse('user_login'))

        # Verify user is removed from database
        self.assertFalse(RegisteredUser.objects.filter(id=user_id).exists())

        # Verify session is flushed
        self.assertNotIn('user_id', self.client.session)

        # Verify profile image file is cleaned up from storage
        self.assertFalse(default_storage.exists(image_name))

    def test_user_self_deletion_json_api(self):
        """Self-deletion via JSON request returns clean JSON payload."""
        self._login_user(self.user)
        response = self.client.post(
            reverse('delete_account'),
            data={'password': 'SecretPassword123!'},
            HTTP_ACCEPT='application/json'
        )
        self.assertEqual(response.status_code, 200)
        json_data = response.json()
        self.assertTrue(json_data.get('success'))
        self.assertIn('permanently deleted', json_data.get('message', ''))

    def test_user_cannot_delete_account_with_wrong_password(self):
        """Self-deletion fails with 403 when incorrect password is provided; account remains intact."""
        self._login_user(self.user)
        user_id = self.user.id
        image_name = self.user.image.name

        response = self.client.post(
            reverse('delete_account'),
            data={'password': 'WrongPassword123'},
            HTTP_ACCEPT='application/json'
        )
        self.assertEqual(response.status_code, 403)
        self.assertFalse(response.json().get('success'))

        # Verify account and image are still preserved
        self.assertTrue(RegisteredUser.objects.filter(id=user_id).exists())
        self.assertTrue(default_storage.exists(image_name))

    def test_user_cannot_delete_account_without_password(self):
        """Self-deletion fails with 400 when password is omitted."""
        self._login_user(self.user)
        response = self.client.post(
            reverse('delete_account'),
            data={},
            HTTP_ACCEPT='application/json'
        )
        self.assertEqual(response.status_code, 400)
        self.assertTrue(RegisteredUser.objects.filter(id=self.user.id).exists())

    def test_unauthenticated_user_cannot_access_deletion(self):
        """Unauthenticated requests cannot access delete-account."""
        response = self.client.post(reverse('delete_account'), {'password': 'any'})
        self.assertEqual(response.status_code, 302)
        self.assertEqual(response.url, reverse('user_login'))

    # --- 2. Parameter Manipulation / IDOR Prevention ---

    def test_user_cannot_delete_another_user_by_tampering_parameters(self):
        """
        Even if an attacker passes another user's ID in POST parameters,
        the deletion strictly operates on the session user_id.
        """
        self._login_user(self.user)  # Alice is logged in
        bob_id = self.user2.id
        bob_image = self.user2.image.name

        # Alice attempts to delete Bob by passing user_id=bob_id and Bob's password
        response = self.client.post(
            reverse('delete_account'),
            data={'user_id': bob_id, 'id': bob_id, 'password': 'BobPassword456!'},
            HTTP_ACCEPT='application/json'
        )
        # Because session belongs to Alice, Bob's password does not match Alice's password
        self.assertEqual(response.status_code, 403)

        # Bob's account and image must remain untouched
        self.assertTrue(RegisteredUser.objects.filter(id=bob_id).exists())
        self.assertTrue(default_storage.exists(bob_image))

        # Alice's account must also remain untouched because password didn't match Alice
        self.assertTrue(RegisteredUser.objects.filter(id=self.user.id).exists())

    # --- 3. Related Records, OTP, and Session Cleanup ---

    def test_in_memory_otp_is_cleared_on_deletion(self):
        """Pending OTP codes in otp_storage dictionary are purged when user is deleted."""
        otp_storage[self.user.email] = '654321'
        self._login_user(self.user)

        self.client.post(
            reverse('delete_account'),
            data={'password': 'SecretPassword123!'},
            HTTP_ACCEPT='application/json'
        )

        self.assertNotIn(self.user.email, otp_storage)

    def test_active_sessions_in_db_are_invalidated(self):
        """All sessions associated with the deleted user are removed from Session table."""
        SessionStore = import_module(settings.SESSION_ENGINE).SessionStore
        user_session = SessionStore()
        user_session['user_id'] = self.user.id
        user_session.create()
        created_session_key = user_session.session_key

        self.assertTrue(Session.objects.filter(session_key=created_session_key).exists())

        # Execute deletion
        self._login_user(self.user)
        self.client.post(
            reverse('delete_account'),
            data={'password': 'SecretPassword123!'},
            HTTP_ACCEPT='application/json'
        )

        # Verify the session in the database was invalidated
        self.assertFalse(Session.objects.filter(session_key=created_session_key).exists())

    def test_stale_session_is_blocked_by_user_required_after_deletion(self):
        """
        If a user account was deleted while holding an active session cookie,
        subsequent requests to protected views are blocked, session flushed, and redirected.
        """
        self._login_user(self.user)
        # Delete user directly (simulating admin action or backend deletion)
        delete_user_account(self.user)

        # Now attempt to visit protected view
        response = self.client.get(reverse('user_homepage'))
        self.assertEqual(response.status_code, 302)
        self.assertEqual(response.url, reverse('user_login'))
        self.assertNotIn('user_id', self.client.session)

    # --- 4. Shared Files and Unrelated Data Protection ---

    def test_shared_image_file_is_not_deleted_if_used_by_another_user(self):
        """
        If two users happen to share the same image file reference,
        deleting one user must NOT delete the file on disk.
        """
        shared_image_name = 'user_images/shared_asset.gif'
        default_storage.save(shared_image_name, SimpleUploadedFile('shared.gif', self.dummy_image_bytes))

        # Assign shared image to both users
        self.user.image.name = shared_image_name
        self.user.save()
        self.user2.image.name = shared_image_name
        self.user2.save()

        self.assertTrue(default_storage.exists(shared_image_name))

        # Delete user 1
        delete_user_account(self.user)

        # The image must STILL exist because user2 references it
        self.assertTrue(default_storage.exists(shared_image_name))

        # Delete user 2
        delete_user_account(self.user2)

        # Now that no users reference it, it should be deleted
        self.assertFalse(default_storage.exists(shared_image_name))

    def test_safe_path_validator_prevents_deleting_system_assets(self):
        """Path validator must reject traversal and shared system files."""
        self.assertFalse(is_safe_user_image_path(''))
        self.assertFalse(is_safe_user_image_path('../secret.txt'))
        self.assertFalse(is_safe_user_image_path('/etc/passwd'))
        self.assertFalse(is_safe_user_image_path('app-release.apk'))
        self.assertFalse(is_safe_user_image_path('user_images/app-release.apk'))
        self.assertFalse(is_safe_user_image_path('behavior_anomaly_dataset.csv'))
        self.assertFalse(is_safe_user_image_path('models/random_forest.pkl'))
        self.assertTrue(is_safe_user_image_path('user_images/custom_photo.jpg'))

    # --- 5. Admin Deletion & Safe Repeated Requests ---

    def test_admin_can_delete_user(self):
        """Admin user can delete any registered user via admin delete endpoint."""
        self._login_admin()
        user_id = self.user.id
        image_name = self.user.image.name

        response = self.client.get(reverse('delete_user', kwargs={'user_id': user_id}))
        self.assertEqual(response.status_code, 302)
        self.assertEqual(response.url, reverse('admin_dashboard'))

        # User is deleted
        self.assertFalse(RegisteredUser.objects.filter(id=user_id).exists())
        self.assertFalse(default_storage.exists(image_name))

    def test_repeated_deletion_requests_are_safe(self):
        """Repeated deletion attempts on an already deleted user do not raise 500 error."""
        self._login_admin()
        user_id = self.user.id

        # First deletion
        response1 = self.client.get(reverse('delete_user', kwargs={'user_id': user_id}))
        self.assertEqual(response1.status_code, 302)

        # Second deletion on same user_id
        response2 = self.client.get(reverse('delete_user', kwargs={'user_id': user_id}))
        self.assertEqual(response2.status_code, 302)
        self.assertEqual(response2.url, reverse('admin_dashboard'))

        # JSON response returns 404 cleanly
        response_json = self.client.get(
            reverse('delete_user', kwargs={'user_id': user_id}),
            HTTP_ACCEPT='application/json'
        )
        self.assertEqual(response_json.status_code, 404)
        self.assertFalse(response_json.json().get('success'))

    # --- 6. Error and Failure Handling ---

    def test_database_failure_does_not_report_success(self):
        """If a DatabaseError occurs during deletion, the function returns False and rolls back."""
        with patch.object(RegisteredUser, 'delete', side_effect=DatabaseError("Connection dropped")):
            success, message = delete_user_account(self.user)
            self.assertFalse(success)
            self.assertIn("Database error", message)
            # User must still exist in DB
            self.assertTrue(RegisteredUser.objects.filter(id=self.user.id).exists())
