import pytest
from rest_framework.test import APIClient

from apps.accounts.models import User
from apps.trips.models import TripMember, TripRole, TripStatus


@pytest.mark.django_db
def test_unauthenticated_trips_denied(api_client):
    resp = api_client.get("/api/trips")
    assert resp.status_code in (401, 403)


@pytest.mark.django_db
def test_create_and_list_trips(auth_client):
    create_resp = auth_client.post("/api/trips", {"title": "Paris"}, format="json")
    assert create_resp.status_code == 201

    list_resp = auth_client.get("/api/trips")
    assert list_resp.status_code == 200
    assert len(list_resp.data) == 1
    assert list_resp.data[0]["title"] == "Paris"


@pytest.mark.django_db
def test_trip_permissions_viewer_cannot_update_owner_can_update(auth_client, user):
    owner = user
    viewer = User.objects.create_user(email="viewer@example.com", password="Password123!")

    create_resp = auth_client.post("/api/trips", {"title": "Rome"}, format="json")
    trip_id = create_resp.data["id"]

    TripMember.objects.create(
        trip_id=trip_id,
        user=viewer,
        role=TripRole.VIEWER,
        status=TripStatus.ACTIVE,
    )

    viewer_client = APIClient()
    viewer_client.force_authenticate(user=viewer)

    viewer_resp = viewer_client.patch(
        f"/api/trips/{trip_id}", {"title": "Rome Updated"}, format="json"
    )
    assert viewer_resp.status_code == 403

    owner_resp = auth_client.patch(
        f"/api/trips/{trip_id}", {"title": "Rome Updated"}, format="json"
    )
    assert owner_resp.status_code == 200
    assert owner_resp.data["title"] == "Rome Updated"
