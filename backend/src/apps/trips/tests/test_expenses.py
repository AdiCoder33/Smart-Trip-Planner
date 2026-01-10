import pytest
from rest_framework.test import APIClient

from apps.accounts.models import User
from apps.trips.models import TripMember, TripRole, TripStatus


@pytest.mark.django_db
def test_expense_create_and_summary(auth_client, user):
    trip_resp = auth_client.post("/api/trips", {"title": "Expense Trip"}, format="json")
    trip_id = trip_resp.data["id"]

    expense_resp = auth_client.post(
        f"/api/trips/{trip_id}/expenses",
        {"title": "Hotel", "amount": "120.00", "currency": "USD"},
        format="json",
    )
    assert expense_resp.status_code == 201
    assert expense_resp.data["title"] == "Hotel"
    assert expense_resp.data["currency"] == "USD"
    assert len(expense_resp.data["splits"]) == 1

    summary_resp = auth_client.get(f"/api/trips/{trip_id}/expenses/summary")
    assert summary_resp.status_code == 200
    assert summary_resp.data[0]["paid"] == "120.00"


@pytest.mark.django_db
def test_expense_permissions_viewer_cannot_create(auth_client, user):
    trip_resp = auth_client.post("/api/trips", {"title": "Expense Trip"}, format="json")
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
        f"/api/trips/{trip_id}/expenses",
        {"title": "Taxi", "amount": "20.00"},
        format="json",
    )
    assert resp.status_code == 403
