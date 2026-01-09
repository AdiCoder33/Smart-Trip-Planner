import pytest
from rest_framework.test import APIClient

from apps.accounts.models import User
from apps.trips.models import TripMember, TripRole, TripStatus


@pytest.mark.django_db
def test_itinerary_crud_and_reorder(auth_client, user):
    trip_resp = auth_client.post("/api/trips", {"title": "Test Trip"}, format="json")
    trip_id = trip_resp.data["id"]

    item1_resp = auth_client.post(
        f"/api/trips/{trip_id}/itinerary",
        {"title": "Check in"},
        format="json",
    )
    item2_resp = auth_client.post(
        f"/api/trips/{trip_id}/itinerary",
        {"title": "Dinner"},
        format="json",
    )

    list_resp = auth_client.get(f"/api/trips/{trip_id}/itinerary")
    assert list_resp.status_code == 200
    assert [item["title"] for item in list_resp.data] == ["Check in", "Dinner"]

    reorder_resp = auth_client.post(
        f"/api/trips/{trip_id}/itinerary/reorder",
        {
            "items": [
                {"id": item1_resp.data["id"], "sort_order": 1},
                {"id": item2_resp.data["id"], "sort_order": 0},
            ]
        },
        format="json",
    )
    assert reorder_resp.status_code == 200
    assert [item["title"] for item in reorder_resp.data] == ["Dinner", "Check in"]


@pytest.mark.django_db
def test_itinerary_permissions_viewer_cannot_create(auth_client, user):
    trip_resp = auth_client.post("/api/trips", {"title": "Team Trip"}, format="json")
    trip_id = trip_resp.data["id"]

    viewer = User.objects.create_user(email="viewer@example.com", password="Password123!")
    TripMember.objects.create(
        trip_id=trip_id,
        user=viewer,
        role=TripRole.VIEWER,
        status=TripStatus.ACTIVE,
    )

    viewer_client = APIClient()
    viewer_client.force_authenticate(user=viewer)

    resp = viewer_client.post(
        f"/api/trips/{trip_id}/itinerary",
        {"title": "Museum"},
        format="json",
    )
    assert resp.status_code == 403
