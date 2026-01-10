import hashlib
import logging
import secrets
from datetime import timedelta

from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from django.conf import settings
from django.core.mail import send_mail
from django.db import transaction
from django.db.models import Count, Max, Prefetch
from django.shortcuts import get_object_or_404
from django.utils.dateparse import parse_datetime
from django.utils import timezone
from rest_framework import permissions, status, viewsets
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import (
    ChatMessage,
    InviteStatus,
    ItineraryItem,
    Poll,
    PollOption,
    Trip,
    TripInvite,
    TripMember,
    TripRole,
    TripStatus,
    Vote,
)
from .permissions import get_trip_member, is_editor_or_owner, is_owner, TripPermission
from .serializers import (
    ChatMessageSerializer,
    InviteAcceptSerializer,
    InviteRevokeSerializer,
    ItineraryItemSerializer,
    ItineraryReorderSerializer,
    PollCreateSerializer,
    PollSerializer,
    PollVoteSerializer,
    TripInviteCreateSerializer,
    TripInviteSerializer,
    TripMemberSerializer,
    TripSerializer,
)

logger = logging.getLogger("chat")


class TripViewSet(viewsets.ModelViewSet):
    serializer_class = TripSerializer
    permission_classes = [permissions.IsAuthenticated, TripPermission]

    def get_queryset(self):
        return (
            Trip.objects.filter(
                memberships__user=self.request.user,
                memberships__status=TripStatus.ACTIVE,
            )
            .select_related("created_by")
            .distinct()
        )

    def perform_create(self, serializer):
        with transaction.atomic():
            trip = serializer.save(created_by=self.request.user)
            TripMember.objects.create(
                trip=trip,
                user=self.request.user,
                role=TripRole.OWNER,
                status=TripStatus.ACTIVE,
            )


def _hash_token(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def _get_trip_or_404(trip_id):
    return get_object_or_404(Trip, id=trip_id)


def _require_member(request, trip):
    member = get_trip_member(request.user, trip)
    if member is None:
        raise PermissionDenied("Not a trip member.")
    return member


class TripMembersView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, trip_id):
        trip = _get_trip_or_404(trip_id)
        _require_member(request, trip)
        members = (
            TripMember.objects.filter(trip=trip, status=TripStatus.ACTIVE)
            .select_related("user")
            .order_by("created_at")
        )
        serializer = TripMemberSerializer(members, many=True)
        return Response(serializer.data)


class TripChatMessagesView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, trip_id):
        trip = _get_trip_or_404(trip_id)
        _require_member(request, trip)

        limit_raw = request.query_params.get("limit", "50")
        try:
            limit = min(int(limit_raw), 200)
        except ValueError:
            raise ValidationError("limit must be an integer.")

        before = request.query_params.get("before")
        before_dt = None
        if before:
            before_dt = parse_datetime(before)
            if before_dt is None:
                raise ValidationError("before must be an ISO 8601 datetime.")
            if timezone.is_naive(before_dt):
                before_dt = timezone.make_aware(before_dt, timezone.get_current_timezone())

        queryset = (
            ChatMessage.objects.filter(trip=trip)
            .select_related("sender")
            .order_by("-created_at")
        )
        if before_dt:
            queryset = queryset.filter(created_at__lt=before_dt)

        messages = list(queryset[:limit])
        messages.reverse()
        return Response(ChatMessageSerializer(messages, many=True).data)

    def post(self, request, trip_id):
        trip = _get_trip_or_404(trip_id)
        member = _require_member(request, trip)
        if not member:
            raise PermissionDenied("Not a trip member.")

        content = (request.data.get("content") or "").strip()
        if not content:
            raise ValidationError("content is required.")

        client_id = request.data.get("client_id")
        if client_id:
            existing = (
                ChatMessage.objects.filter(trip=trip, sender=request.user, client_id=client_id)
                .select_related("sender")
                .first()
            )
            if existing:
                return Response(ChatMessageSerializer(existing).data, status=status.HTTP_200_OK)

        message = ChatMessage.objects.create(
            trip=trip,
            sender=request.user,
            content=content,
            client_id=client_id,
        )
        message = ChatMessage.objects.select_related("sender").get(id=message.id)

        payload = ChatMessageSerializer(message).data
        channel_layer = get_channel_layer()
        if channel_layer is not None:
            try:
                async_to_sync(channel_layer.group_send)(
                    f"trip_{trip_id}",
                    {"type": "chat.message", "message": payload},
                )
            except Exception:  # pragma: no cover - best-effort broadcast
                logger.exception("chat broadcast failed", extra={"trip_id": str(trip_id)})

        return Response(payload, status=status.HTTP_201_CREATED)


class TripItineraryView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, trip_id):
        trip = _get_trip_or_404(trip_id)
        _require_member(request, trip)
        items = ItineraryItem.objects.filter(trip=trip).order_by("sort_order")
        serializer = ItineraryItemSerializer(items, many=True)
        return Response(serializer.data)

    def post(self, request, trip_id):
        trip = _get_trip_or_404(trip_id)
        member = _require_member(request, trip)
        if not is_editor_or_owner(member):
            raise PermissionDenied("Insufficient permissions.")

        serializer = ItineraryItemSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        max_sort = (
            ItineraryItem.objects.filter(trip=trip).aggregate(max_sort=Max("sort_order")).get("max_sort")
            or -1
        )
        item = serializer.save(
            trip=trip,
            created_by=request.user,
            sort_order=max_sort + 1,
        )
        return Response(ItineraryItemSerializer(item).data, status=status.HTTP_201_CREATED)


class ItineraryItemDetailView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def patch(self, request, item_id):
        item = get_object_or_404(ItineraryItem, id=item_id)
        member = _require_member(request, item.trip)
        if not is_editor_or_owner(member):
            raise PermissionDenied("Insufficient permissions.")

        serializer = ItineraryItemSerializer(item, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)

    def delete(self, request, item_id):
        item = get_object_or_404(ItineraryItem, id=item_id)
        member = _require_member(request, item.trip)
        if not is_editor_or_owner(member):
            raise PermissionDenied("Insufficient permissions.")
        item.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class TripItineraryReorderView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, trip_id):
        trip = _get_trip_or_404(trip_id)
        member = _require_member(request, trip)
        if not is_editor_or_owner(member):
            raise PermissionDenied("Insufficient permissions.")

        serializer = ItineraryReorderSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        items = serializer.validated_data["items"]
        ids = [item["id"] for item in items]

        queryset = ItineraryItem.objects.filter(trip=trip, id__in=ids)
        if queryset.count() != len(ids):
            raise ValidationError("All items must belong to the trip.")

        sort_map = {item["id"]: item["sort_order"] for item in items}
        with transaction.atomic():
            for item in queryset:
                item.sort_order = sort_map[item.id]
            ItineraryItem.objects.bulk_update(queryset, ["sort_order", "updated_at"])

        ordered = ItineraryItem.objects.filter(trip=trip).order_by("sort_order")
        return Response(ItineraryItemSerializer(ordered, many=True).data)


class TripInvitesView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, trip_id):
        trip = _get_trip_or_404(trip_id)
        member = _require_member(request, trip)
        if not is_owner(member):
            raise PermissionDenied("Only owners can view invites.")
        invites = TripInvite.objects.filter(trip=trip).order_by("-created_at")
        return Response(TripInviteSerializer(invites, many=True).data)

    def post(self, request, trip_id):
        trip = _get_trip_or_404(trip_id)
        member = _require_member(request, trip)
        if not is_owner(member):
            raise PermissionDenied("Only owners can invite.")

        serializer = TripInviteCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        email = serializer.validated_data["email"].lower()
        role = serializer.validated_data["role"]

        if TripMember.objects.filter(trip=trip, user__email__iexact=email).exists():
            raise ValidationError("User is already a trip member.")

        existing = TripInvite.objects.filter(
            trip=trip,
            email=email,
            status=InviteStatus.PENDING,
            expires_at__gt=timezone.now(),
        ).first()
        if existing:
            raise ValidationError("An active invite already exists.")

        token = secrets.token_urlsafe(32)
        token_hash = _hash_token(token)
        expires_at = timezone.now() + timedelta(hours=settings.INVITE_EXPIRES_HOURS)

        invite = TripInvite.objects.create(
            trip=trip,
            email=email,
            role=role,
            invited_by=request.user,
            token_hash=token_hash,
            status=InviteStatus.PENDING,
            expires_at=expires_at,
        )

        subject = settings.INVITE_EMAIL_SUBJECT
        message = (
            "You've been invited to collaborate on a trip.\n\n"
            f"Trip: {trip.title}\n"
            f"Role: {role}\n"
            f"Token: {token}\n\n"
            "Use this token in the app to accept the invite."
        )
        send_mail(
            subject=subject,
            message=message,
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[email],
            fail_silently=False,
        )

        return Response(TripInviteSerializer(invite).data, status=status.HTTP_201_CREATED)


class InviteAcceptView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = InviteAcceptSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        token = serializer.validated_data["token"]
        token_hash = _hash_token(token)

        invite = TripInvite.objects.filter(token_hash=token_hash).first()
        if invite is None:
            raise ValidationError("Invalid invite token.")

        if invite.status != InviteStatus.PENDING:
            raise ValidationError("Invite is no longer active.")

        if invite.is_expired():
            invite.status = InviteStatus.EXPIRED
            invite.save(update_fields=["status"])
            raise ValidationError("Invite has expired.")

        if request.user.email.lower() != invite.email.lower():
            raise PermissionDenied("Invite email does not match your account.")

        member, _ = TripMember.objects.get_or_create(
            trip=invite.trip,
            user=request.user,
            defaults={"role": invite.role, "status": TripStatus.ACTIVE},
        )
        invite.status = InviteStatus.ACCEPTED
        invite.save(update_fields=["status"])
        return Response(TripMemberSerializer(member).data)


class InviteRevokeView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = InviteRevokeSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        invite = get_object_or_404(TripInvite, id=serializer.validated_data["invite_id"])
        member = _require_member(request, invite.trip)
        if not is_owner(member):
            raise PermissionDenied("Only owners can revoke invites.")
        if invite.status != InviteStatus.PENDING:
            raise ValidationError("Invite is not pending.")
        invite.status = InviteStatus.REVOKED
        invite.save(update_fields=["status"])
        return Response(TripInviteSerializer(invite).data)


class TripPollsView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, trip_id):
        trip = _get_trip_or_404(trip_id)
        _require_member(request, trip)
        options_qs = PollOption.objects.annotate(vote_count=Count("votes"))
        polls = (
            Poll.objects.filter(trip=trip)
            .prefetch_related(
                Prefetch("options", queryset=options_qs),
                Prefetch(
                    "votes",
                    queryset=Vote.objects.filter(user=request.user),
                    to_attr="user_votes",
                ),
            )
            .order_by("-created_at")
        )
        serializer = PollSerializer(polls, many=True, context={"request": request})
        return Response(serializer.data)

    def post(self, request, trip_id):
        trip = _get_trip_or_404(trip_id)
        member = _require_member(request, trip)
        if not is_editor_or_owner(member):
            raise PermissionDenied("Insufficient permissions.")

        serializer = PollCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        question = serializer.validated_data["question"]
        options = [option.strip() for option in serializer.validated_data["options"] if option.strip()]
        if len(options) < 2:
            raise ValidationError("At least two options are required.")

        with transaction.atomic():
            poll = Poll.objects.create(trip=trip, question=question, created_by=request.user)
            PollOption.objects.bulk_create(
                [PollOption(poll=poll, text=option) for option in options]
            )

        options_qs = PollOption.objects.annotate(vote_count=Count("votes"))
        poll = (
            Poll.objects.filter(id=poll.id)
            .prefetch_related(Prefetch("options", queryset=options_qs))
            .first()
        )
        return Response(PollSerializer(poll, context={"request": request}).data, status=status.HTTP_201_CREATED)


class PollDetailView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, poll_id):
        poll = get_object_or_404(Poll, id=poll_id)
        _require_member(request, poll.trip)
        options_qs = PollOption.objects.annotate(vote_count=Count("votes"))
        poll = (
            Poll.objects.filter(id=poll_id)
            .prefetch_related(
                Prefetch("options", queryset=options_qs),
                Prefetch(
                    "votes",
                    queryset=Vote.objects.filter(user=request.user),
                    to_attr="user_votes",
                ),
            )
            .first()
        )
        return Response(PollSerializer(poll, context={"request": request}).data)

    def patch(self, request, poll_id):
        poll = get_object_or_404(Poll, id=poll_id)
        member = _require_member(request, poll.trip)
        if not is_editor_or_owner(member):
            raise PermissionDenied("Insufficient permissions.")

        is_active = request.data.get("is_active")
        if is_active is None:
            raise ValidationError("is_active is required.")
        if isinstance(is_active, str):
            is_active = is_active.lower() == "true"
        if not isinstance(is_active, bool):
            raise ValidationError("is_active must be a boolean.")
        poll.is_active = is_active
        poll.save(update_fields=["is_active", "updated_at"])
        options_qs = PollOption.objects.annotate(vote_count=Count("votes"))
        poll = (
            Poll.objects.filter(id=poll_id)
            .prefetch_related(
                Prefetch("options", queryset=options_qs),
                Prefetch(
                    "votes",
                    queryset=Vote.objects.filter(user=request.user),
                    to_attr="user_votes",
                ),
            )
            .first()
        )
        return Response(PollSerializer(poll, context={"request": request}).data)


class PollVoteView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, poll_id):
        poll = get_object_or_404(Poll, id=poll_id)
        _require_member(request, poll.trip)
        if not poll.is_active:
            raise ValidationError("Poll is closed.")

        serializer = PollVoteSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        option = get_object_or_404(PollOption, id=serializer.validated_data["option_id"], poll=poll)

        Vote.objects.update_or_create(
            poll=poll,
            user=request.user,
            defaults={"option": option},
        )

        options_qs = PollOption.objects.annotate(vote_count=Count("votes"))
        poll = (
            Poll.objects.filter(id=poll_id)
            .prefetch_related(
                Prefetch("options", queryset=options_qs),
                Prefetch(
                    "votes",
                    queryset=Vote.objects.filter(user=request.user),
                    to_attr="user_votes",
                ),
            )
            .first()
        )
        return Response(PollSerializer(poll, context={"request": request}).data)
