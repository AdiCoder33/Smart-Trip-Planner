from django.conf import settings
from django.db import migrations, models
import uuid


class Migration(migrations.Migration):
    dependencies = [
        ("trips", "0003_chat_message"),
    ]

    operations = [
        migrations.AlterField(
            model_name="chatmessage",
            name="content",
            field=models.TextField(blank=True),
        ),
        migrations.AddField(
            model_name="chatmessage",
            name="encrypted_content",
            field=models.TextField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name="chatmessage",
            name="encryption_version",
            field=models.PositiveIntegerField(blank=True, null=True),
        ),
        migrations.CreateModel(
            name="TripChatKey",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("key", models.CharField(max_length=255)),
                ("version", models.PositiveIntegerField(default=1)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                (
                    "trip",
                    models.OneToOneField(on_delete=models.CASCADE, related_name="chat_key", to="trips.trip"),
                ),
            ],
        ),
        migrations.CreateModel(
            name="Expense",
            fields=[
                ("id", models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False, serialize=False)),
                ("title", models.CharField(max_length=255)),
                ("amount", models.DecimalField(max_digits=10, decimal_places=2)),
                ("currency", models.CharField(max_length=3, default="USD")),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                (
                    "created_by",
                    models.ForeignKey(
                        on_delete=models.CASCADE,
                        related_name="expenses_created",
                        to=settings.AUTH_USER_MODEL,
                    ),
                ),
                (
                    "paid_by",
                    models.ForeignKey(
                        on_delete=models.CASCADE,
                        related_name="expenses_paid",
                        to=settings.AUTH_USER_MODEL,
                    ),
                ),
                (
                    "trip",
                    models.ForeignKey(on_delete=models.CASCADE, related_name="expenses", to="trips.trip"),
                ),
            ],
            options={
                "ordering": ["-created_at"],
                "indexes": [
                    models.Index(fields=["trip", "created_at"], name="trips_expense_trip_created_idx"),
                ],
            },
        ),
        migrations.CreateModel(
            name="ExpenseSplit",
            fields=[
                ("id", models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False, serialize=False)),
                ("amount", models.DecimalField(max_digits=10, decimal_places=2)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                (
                    "expense",
                    models.ForeignKey(
                        on_delete=models.CASCADE,
                        related_name="splits",
                        to="trips.expense",
                    ),
                ),
                (
                    "user",
                    models.ForeignKey(
                        on_delete=models.CASCADE,
                        related_name="expense_splits",
                        to=settings.AUTH_USER_MODEL,
                    ),
                ),
            ],
            options={
                "indexes": [
                    models.Index(fields=["user"], name="trips_expense_split_user_idx"),
                    models.Index(fields=["expense"], name="trips_exp_split_exp_idx"),
                ],
                "constraints": [
                    models.UniqueConstraint(
                        fields=("expense", "user"),
                        name="unique_expense_split",
                    )
                ],
            },
        ),
    ]
