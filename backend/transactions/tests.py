from datetime import date

from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from rest_framework_simplejwt.tokens import RefreshToken

from categories.models import Category
from transactions.models import RecurringTransaction, Transaction

User = get_user_model()


class RecurringTransactionCommandTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email='recurring@example.com',
            username='recurring',
            password='StrongPass123',
        )
        self.category = Category.objects.create(
            user=self.user,
            name='Rent',
            type='expense',
            color='#FF0000',
            icon='home',
        )
        self.recurring = RecurringTransaction.objects.create(
            user=self.user,
            category=self.category,
            type='expense',
            amount='1200.00',
            description='Monthly rent',
            currency='USD',
            frequency='monthly',
            next_run_date=date.today(),
        )

    def test_process_recurring_transactions_command(self):
        from django.core.management import call_command

        self.assertEqual(Transaction.objects.count(), 0)
        call_command('process_recurring_transactions')
        self.assertEqual(Transaction.objects.count(), 1)

        self.recurring.refresh_from_db()
        self.assertEqual(self.recurring.execution_count, 1)
        self.assertGreater(self.recurring.next_run_date, date.today())

    def test_recurring_transactions_api_list(self):
        token = str(RefreshToken.for_user(self.user).access_token)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        url = reverse('recurring-transaction-list')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
