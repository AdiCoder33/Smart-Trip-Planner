import re

import pytest
from django.core import mail
from rest_framework.test import APIClient

from apps.accounts.models import User
from apps.trips.models import TripMember, TripRole, TripStatus


@pytest.mark.django_db
def test_invite_create_and_accept(auth_client, user):
    trip_resp = auth_client.post("/api/trips", {"title": "Invite Trip"}, format="json")
    trip_id = trip_resp.data["id"]

    invite_resp = auth_client.post(
        f"/api/trips/{trip_id}/invites",
        {"email": "invitee@example.com", "role": "viewer"},
        format="json",
    )
    assert invite_resp.status_code == 201
    assert len(mail.outbox) == 1

    body = mail.outbox[0].body
    match = re.search(r"Token:\s*(\S+)", body)
    assert match is not None
    token = match.group(1)

    invitee = User.objects.create_user(email="invitee@example.com", password="Password123!")
    invitee_client = APIClient()
    invitee_client.force_authenticate(user=invitee)

    accept_resp = invitee_client.post("/api/invites/accept", {"token": token}, format="json")
    assert accept_resp.status_code == 200

    assert TripMember.objects.filter(
        trip_id=trip_id,
        user=invitee,
        role=TripRole.VIEWER,
        status=TripStatus.ACTIVE,
    ).exists()


@pytest.mark.django_db
def test_invite_requires_owner(auth_client, user):
    trip_resp = auth_client.post("/api/trips", {"title": "Invite Trip"}, format="json")
    trip_id = trip_resp.data["id"]

    editor = User.objects.create_user(email="editor@example.com", password="Password123!")
    TripMember.objects.create(
        trip_id=trip_id,
        user=editor,
        role=TripRole.EDITOR,
        status=TripStatus.ACTIVE,
    )

    editor_client = APIClient()
    editor_client.force_authenticate(user=editor)

    resp = editor_client.post(
        f"/api/trips/{trip_id}/invites",
        {"email": "other@example.com", "role": "viewer"},
        format="json",
    )
    assert resp.status_code == 403
