import uuid

from django.conf import settings
from django.db import models
from django.utils import timezone


class Trip(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=255)
    destination = models.CharField(max_length=255, blank=True)
    start_date = models.DateField(null=True, blank=True)
    end_date = models.DateField(null=True, blank=True)
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="created_trips")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["created_by"], name="trips_trip_created_by_idx"),
        ]

    def __str__(self) -> str:
        return self.title


class TripRole(models.TextChoices):
    OWNER = "owner", "Owner"
    EDITOR = "editor", "Editor"
    VIEWER = "viewer", "Viewer"


class TripStatus(models.TextChoices):
    ACTIVE = "active", "Active"


class TripMember(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    trip = models.ForeignKey(Trip, on_delete=models.CASCADE, related_name="memberships")
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="trip_memberships")
    role = models.CharField(max_length=20, choices=TripRole.choices, default=TripRole.OWNER)
    status = models.CharField(max_length=20, choices=TripStatus.choices, default=TripStatus.ACTIVE)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["trip", "user"], name="unique_trip_member"),
        ]
        indexes = [
            models.Index(fields=["user"], name="trips_tripmember_user_idx"),
            models.Index(fields=["trip"], name="trips_tripmember_trip_idx"),
        ]

    def __str__(self) -> str:
        return f"{self.user_id} -> {self.trip_id} ({self.role})"


class ItineraryItem(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    trip = models.ForeignKey(Trip, on_delete=models.CASCADE, related_name="itinerary_items")
    title = models.CharField(max_length=255)
    notes = models.TextField(blank=True)
    location = models.CharField(max_length=255, blank=True)
    start_time = models.TimeField(null=True, blank=True)
    end_time = models.TimeField(null=True, blank=True)
    date = models.DateField(null=True, blank=True)
    sort_order = models.IntegerField()
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="created_itinerary_items",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["sort_order"]
        indexes = [
            models.Index(fields=["trip", "date"], name="trips_itinerary_trip_date_idx"),
            models.Index(fields=["trip", "sort_order"], name="trips_itinerary_trip_sort_idx"),
        ]

    def __str__(self) -> str:
        return f"{self.trip_id} - {self.title}"


class InviteStatus(models.TextChoices):
    PENDING = "pending", "Pending"
    ACCEPTED = "accepted", "Accepted"
    EXPIRED = "expired", "Expired"
    REVOKED = "revoked", "Revoked"


class TripInvite(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    trip = models.ForeignKey(Trip, on_delete=models.CASCADE, related_name="invites")
    email = models.EmailField()
    role = models.CharField(max_length=20, choices=TripRole.choices, default=TripRole.VIEWER)
    invited_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="sent_trip_invites",
    )
    token_hash = models.CharField(max_length=128)
    status = models.CharField(max_length=20, choices=InviteStatus.choices, default=InviteStatus.PENDING)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()

    class Meta:
        indexes = [
            models.Index(fields=["trip", "email"], name="trips_invite_trip_email_idx"),
            models.Index(fields=["status"], name="trips_invite_status_idx"),
        ]

    def __str__(self) -> str:
        return f"{self.trip_id} -> {self.email} ({self.status})"

    def is_expired(self) -> bool:
        return self.expires_at <= timezone.now()


class Poll(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    trip = models.ForeignKey(Trip, on_delete=models.CASCADE, related_name="polls")
    question = models.CharField(max_length=255)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="created_polls",
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["trip", "created_at"], name="trips_poll_trip_created_idx"),
        ]

    def __str__(self) -> str:
        return self.question


class PollOption(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    poll = models.ForeignKey(Poll, on_delete=models.CASCADE, related_name="options")
    text = models.CharField(max_length=255)

    class Meta:
        indexes = [
            models.Index(fields=["poll"], name="trips_polloption_poll_idx"),
        ]

    def __str__(self) -> str:
        return self.text


class Vote(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    poll = models.ForeignKey(Poll, on_delete=models.CASCADE, related_name="votes")
    option = models.ForeignKey(PollOption, on_delete=models.CASCADE, related_name="votes")
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="poll_votes")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["poll", "user"], name="unique_poll_vote"),
        ]
        indexes = [
            models.Index(fields=["poll", "user"], name="trips_vote_poll_user_idx"),
        ]

    def __str__(self) -> str:
        return f"{self.poll_id} -> {self.user_id}"
