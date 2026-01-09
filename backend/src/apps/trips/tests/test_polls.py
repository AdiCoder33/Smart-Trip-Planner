import pytest
from rest_framework.test import APIClient

from apps.accounts.models import User
from apps.trips.models import TripMember, TripRole, TripStatus, Vote


@pytest.mark.django_db
def test_poll_create_and_vote_uniqueness(auth_client, user):
    trip_resp = auth_client.post("/api/trips", {"title": "Poll Trip"}, format="json")
    trip_id = trip_resp.data["id"]

    poll_resp = auth_client.post(
        f"/api/trips/{trip_id}/polls",
        {"question": "Where to eat?", "options": ["A", "B", "C"]},
        format="json",
    )
    assert poll_resp.status_code == 201
    poll_id = poll_resp.data["id"]
    option_id = poll_resp.data["options"][0]["id"]
    option_id_2 = poll_resp.data["options"][1]["id"]

    vote_resp = auth_client.post(
        f"/api/polls/{poll_id}/vote",
        {"option_id": option_id},
        format="json",
    )
    assert vote_resp.status_code == 200
    assert Vote.objects.filter(poll_id=poll_id, user=user).count() == 1

    vote_resp_2 = auth_client.post(
        f"/api/polls/{poll_id}/vote",
        {"option_id": option_id_2},
        format="json",
    )
    assert vote_resp_2.status_code == 200
    assert Vote.objects.filter(poll_id=poll_id, user=user).count() == 1


@pytest.mark.django_db
def test_poll_permissions_viewer_cannot_create(auth_client, user):
    trip_resp = auth_client.post("/api/trips", {"title": "Poll Trip"}, format="json")
    trip_id = trip_resp.data["id"]

    viewer = User.objects.create_user(email="viewer2@example.com", password="Password123!")
    TripMember.objects.create(
        trip_id=trip_id,
        user=viewer,
        role=TripRole.VIEWER,
        status=TripStatus.ACTIVE,
    )

    viewer_client = APIClient()
    viewer_client.force_authenticate(user=viewer)

    resp = viewer_client.post(
        f"/api/trips/{trip_id}/polls",
        {"question": "Q", "options": ["A", "B"]},
        format="json",
    )
    assert resp.status_code == 403
