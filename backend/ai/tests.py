from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from rest_framework_simplejwt.tokens import RefreshToken

from ai.models import AIMessage, AIConversation

User = get_user_model()


class AIHistoryTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email='aihistory@example.com',
            username='aihistory',
            password='StrongPass123',
        )
        token = str(RefreshToken.for_user(self.user).access_token)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        self.history_url = reverse('ai-history')
        self.assist_url = reverse('ai-assist')

    def test_assist_persists_messages(self):
        response = self.client.post(
            self.assist_url,
            {
                'message': 'What is my balance?',
                'context': {
                    'currency': 'USD',
                    'total_balance': 100,
                    'total_income': 500,
                    'total_expense': 400,
                    'recent_transactions': [],
                    'categories': [],
                },
            },
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(AIConversation.objects.filter(user=self.user).exists())
        self.assertGreaterEqual(
            AIMessage.objects.filter(conversation__user=self.user).count(),
            2,
        )

    def test_history_returns_saved_messages(self):
        self.client.post(
            self.assist_url,
            {
                'message': 'Hello',
                'context': {'currency': 'USD', 'recent_transactions': [], 'categories': []},
            },
            format='json',
        )

        history_response = self.client.get(self.history_url)
        self.assertEqual(history_response.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(len(history_response.data), 2)

    def test_clear_history(self):
        self.client.post(
            self.assist_url,
            {
                'message': 'Hello',
                'context': {'currency': 'USD', 'recent_transactions': [], 'categories': []},
            },
            format='json',
        )

        clear_response = self.client.delete(self.history_url)
        self.assertEqual(clear_response.status_code, status.HTTP_204_NO_CONTENT)

        history_response = self.client.get(self.history_url)
        self.assertEqual(history_response.data, [])
