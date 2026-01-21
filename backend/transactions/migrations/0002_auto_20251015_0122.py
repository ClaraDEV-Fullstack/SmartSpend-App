# migrations/XXXX_delete_null_transactions.py
from django.db import migrations

def delete_null_transactions(apps, schema_editor):
    Transaction = apps.get_model('transactions', 'Transaction')
    # Delete transactions with no user
    Transaction.objects.filter(user__isnull=True).delete()
    # Delete transactions with no category
    Transaction.objects.filter(category__isnull=True).delete()

class Migration(migrations.Migration):
    dependencies = [
        ('transactions', '0001_initial'),  # or your latest applied migration
    ]

    operations = [
        migrations.RunPython(delete_null_transactions),
    ]
