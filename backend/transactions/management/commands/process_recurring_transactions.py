from datetime import date, timedelta

from django.core.management.base import BaseCommand
from django.utils import timezone

from transactions.models import RecurringTransaction, Transaction


class Command(BaseCommand):
    help = 'Process due recurring transactions and create actual transactions'

    def handle(self, *args, **options):
        today = timezone.now().date()
        due_items = RecurringTransaction.objects.filter(next_run_date__lte=today)

        processed = 0
        for recurring in due_items:
            if recurring.end_date and recurring.next_run_date > recurring.end_date:
                continue

            if (
                recurring.total_executions is not None
                and recurring.execution_count >= recurring.total_executions
            ):
                continue

            Transaction.objects.create(
                user=recurring.user,
                category=recurring.category,
                type=recurring.type,
                amount=recurring.amount,
                description=recurring.description,
                date=recurring.next_run_date,
                currency=recurring.currency,
                is_recurring=True,
                recurrence=recurring.frequency,
            )

            recurring.execution_count += 1
            recurring.next_run_date = self._calculate_next_date(
                recurring.next_run_date,
                recurring.frequency,
            )
            recurring.save(update_fields=['execution_count', 'next_run_date', 'updated_at'])
            processed += 1

        self.stdout.write(self.style.SUCCESS(f'Processed {processed} recurring transaction(s)'))

    def _calculate_next_date(self, current_date, frequency):
        if frequency == 'daily':
            return current_date + timedelta(days=1)
        if frequency == 'weekly':
            return current_date + timedelta(weeks=1)
        if frequency == 'monthly':
            month = current_date.month + 1
            year = current_date.year
            if month > 12:
                month = 1
                year += 1
            day = min(current_date.day, 28)
            return date(year, month, day)
        if frequency == 'yearly':
            return date(current_date.year + 1, current_date.month, current_date.day)
        return current_date + timedelta(days=30)
