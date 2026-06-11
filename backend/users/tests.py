from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

User = get_user_model()


class UserAuthTests(APITestCase):
    def setUp(self):
        self.register_url = reverse('register')
        self.login_url = reverse('login')
        self.profile_url = reverse('user-profile')
        self.delete_url = reverse('delete-account')
        self.user_data = {
            'email': 'test@example.com',
            'username': 'testuser',
            'first_name': 'Test',
            'last_name': 'User',
            'password': 'StrongPass123',
            'password_confirm': 'StrongPass123',
        }

    def _register_and_login(self):
        self.client.post(self.register_url, self.user_data, format='json')
        response = self.client.post(
            self.login_url,
            {
                'email': self.user_data['email'],
                'password': self.user_data['password'],
            },
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        return response.data['access']

    def test_register_user(self):
        response = self.client.post(self.register_url, self.user_data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(User.objects.filter(email=self.user_data['email']).exists())

    def test_login_user(self):
        self.client.post(self.register_url, self.user_data, format='json')
        response = self.client.post(
            self.login_url,
            {
                'email': self.user_data['email'],
                'password': self.user_data['password'],
            },
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('access', response.data)
        self.assertIn('refresh', response.data)

    def test_profile_requires_auth(self):
        response = self.client.get(self.profile_url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_update_profile_patch(self):
        token = self._register_and_login()
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        response = self.client.patch(
            self.profile_url,
            {'first_name': 'Updated'},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['first_name'], 'Updated')

    def test_delete_account_with_password(self):
        token = self._register_and_login()
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        response = self.client.post(
            self.delete_url,
            {'password': self.user_data['password']},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertFalse(User.objects.filter(email=self.user_data['email']).exists())

    def test_delete_account_invalid_password(self):
        token = self._register_and_login()
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        response = self.client.post(
            self.delete_url,
            {'password': 'WrongPassword123'},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_delete_google_style_account_with_confirmation(self):
        user = User.objects.create_user(
            email='google@example.com',
            username='googleuser',
            password=None,
        )
        user.set_unusable_password()
        user.save()

        login_response = self.client.post(
            self.login_url,
            {'email': 'google@example.com', 'password': 'anything'},
            format='json',
        )
        self.assertEqual(login_response.status_code, status.HTTP_400_BAD_REQUEST)

        from rest_framework_simplejwt.tokens import RefreshToken
        token = str(RefreshToken.for_user(user).access_token)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')

        response = self.client.post(
            self.delete_url,
            {'confirmation': 'DELETE'},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertFalse(User.objects.filter(email='google@example.com').exists())


class LogoutTests(APITestCase):
    def setUp(self):
        self.user_data = {
            'email': 'logout@example.com',
            'username': 'logoutuser',
            'first_name': 'Logout',
            'last_name': 'User',
            'password': 'StrongPass123',
            'password_confirm': 'StrongPass123',
        }
        self.client.post(reverse('register'), self.user_data, format='json')
        login_response = self.client.post(
            reverse('login'),
            {
                'email': self.user_data['email'],
                'password': self.user_data['password'],
            },
            format='json',
        )
        self.access = login_response.data['access']
        self.refresh = login_response.data['refresh']

    def test_logout_blacklists_refresh_token(self):
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.access}')
        response = self.client.post(
            reverse('logout'),
            {'refresh': self.refresh},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        refresh_response = self.client.post(
            reverse('token-refresh'),
            {'refresh': self.refresh},
            format='json',
        )
        self.assertEqual(refresh_response.status_code, status.HTTP_401_UNAUTHORIZED)
