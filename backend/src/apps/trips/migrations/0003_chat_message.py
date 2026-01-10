from django.conf import settings
from django.db import migrations, models
from django.db.models import Q
import uuid


class Migration(migrations.Migration):
    dependencies = [
        ("trips", "0002_phase2"),
    ]

    operations = [
        migrations.CreateModel(
            name="ChatMessage",
            fields=[
                ("id", models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False, serialize=False)),
                ("content", models.TextField()),
                ("client_id", models.CharField(max_length=64, null=True, blank=True)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                (
                    "sender",
                    models.ForeignKey(
                        on_delete=models.CASCADE,
                        related_name="sent_chat_messages",
                        to=settings.AUTH_USER_MODEL,
                    ),
                ),
                (
                    "trip",
                    models.ForeignKey(
                        on_delete=models.CASCADE,
                        related_name="chat_messages",
                        to="trips.trip",
                    ),
                ),
            ],
            options={
                "ordering": ["created_at"],
                "indexes": [
                    models.Index(
                        fields=["trip", "created_at"],
                        name="trips_chat_trip_created_idx",
                    )
                ],
                "constraints": [
                    models.UniqueConstraint(
                        fields=("trip", "sender", "client_id"),
                        name="unique_chat_client_id",
                        condition=Q(("client_id__isnull", False)),
                    )
                ],
            },
        ),
    ]
