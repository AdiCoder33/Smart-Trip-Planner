import pytest
from rest_framework.test import APIClient

from apps.accounts.models import User
from apps.trips.models import ChatMessage


@pytest.mark.django_db
def test_chat_message_creation(user, auth_client):
    trip_resp = auth_client.post("/api/trips", {"title": "Chat Trip"}, format="json")
    trip_id = trip_resp.data["id"]

    message = ChatMessage.objects.create(
        trip_id=trip_id,
        sender=user,
        content="Hello",
    )

    assert message.content == "Hello"
    assert str(message.trip_id) == trip_id


@pytest.mark.django_db
def test_chat_messages_list_requires_membership(auth_client, user):
    trip_resp = auth_client.post("/api/trips", {"title": "Chat Trip"}, format="json")
    trip_id = trip_resp.data["id"]

    ChatMessage.objects.create(
        trip_id=trip_id,
        sender=user,
        content="Hello",
    )

    other_user = User.objects.create_user(email="other@example.com", password="Password123!")
    other_client = APIClient()
    other_client.force_authenticate(user=other_user)

    forbidden = other_client.get(f"/api/trips/{trip_id}/chat/messages")
    assert forbidden.status_code == 403

    ok_resp = auth_client.get(f"/api/trips/{trip_id}/chat/messages")
    assert ok_resp.status_code == 200
    assert len(ok_resp.data) == 1
