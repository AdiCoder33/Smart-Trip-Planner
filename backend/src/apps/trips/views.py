import hashlib
import logging
import secrets
from datetime import datetime, timedelta, timezone as dt_timezone
from decimal import Decimal, ROUND_HALF_UP

from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from django.conf import settings
from django.core.mail import send_mail
from django.http import HttpResponse
from django.db import transaction
from django.db.models import Count, Max, Prefetch, Sum, Q
from django.shortcuts import get_object_or_404
from django.utils.dateparse import parse_datetime
from django.utils import timezone
from rest_framework import permissions, status, viewsets
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.exceptions import TokenError
from rest_framework_simplejwt.tokens import AccessToken

from .models import (
    ChatMessage,
    Expense,
    ExpenseSplit,
    InviteStatus,
    ItineraryItem,
    Poll,
    PollOption,
    Trip,
    TripChatKey,
    TripInvite,
    TripMember,
    TripRole,
    TripStatus,
    Vote,
)
from .permissions import get_trip_member, is_editor_or_owner, is_owner, TripPermission
from .serializers import (
    ChatMessageSerializer,
    ExpenseCreateSerializer,
    ExpenseSerializer,
    ExpenseSummarySerializer,
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
    UserLookupSerializer,
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


def _require_member_for_user(user, trip):
    member = TripMember.objects.filter(
        trip=trip,
        user=user,
        status=TripStatus.ACTIVE,
    ).first()
    if member is None:
        raise PermissionDenied("Not a trip member.")
    return member


def _get_user_from_token(token):
    if not token:
        return None
    try:
        access = AccessToken(token)
    except TokenError:
        return None
    user_id = access.get("user_id")
    if not user_id:
        return None
    from django.contrib.auth import get_user_model

    User = get_user_model()
    return User.objects.filter(id=user_id, is_active=True).first()


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


class TripUserSearchView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, trip_id):
        trip = _get_trip_or_404(trip_id)
        member = _require_member(request, trip)
        if not is_owner(member):
            raise PermissionDenied("Only owners can search users.")

        query = (request.query_params.get("q") or "").strip()
        if len(query) < 2:
            return Response([])

        from django.contrib.auth import get_user_model

        User = get_user_model()
        member_ids = TripMember.objects.filter(trip=trip).values_list("user_id", flat=True)
        invited_emails = TripInvite.objects.filter(
            trip=trip,
            status=InviteStatus.PENDING,
            expires_at__gt=timezone.now(),
        ).values_list("email", flat=True)

        users = (
            User.objects.filter(is_active=True)
            .filter(Q(email__icontains=query) | Q(name__icontains=query))
            .exclude(id__in=member_ids)
            .exclude(email__in=invited_emails)
            .order_by("email")[:10]
        )

        return Response(UserLookupSerializer(users, many=True).data)


class TripChatKeyView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, trip_id):
        trip = _get_trip_or_404(trip_id)
        _require_member(request, trip)

        chat_key, _ = TripChatKey.objects.get_or_create(
            trip=trip,
            defaults={"key": secrets.token_urlsafe(32), "version": 1},
        )
        return Response({"key": chat_key.key, "version": chat_key.version})


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
        encrypted_content = (request.data.get("encrypted_content") or "").strip()
        if not content and not encrypted_content:
            raise ValidationError("content or encrypted_content is required.")

        encryption_version = request.data.get("encryption_version")
        if encrypted_content:
            if encryption_version is None:
                encryption_version = 1
            else:
                try:
                    encryption_version = int(encryption_version)
                except (TypeError, ValueError):
                    raise ValidationError("encryption_version must be an integer.")
        else:
            encryption_version = None

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
            content=content or "",
            encrypted_content=encrypted_content or None,
            encryption_version=encryption_version,
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


class TripCalendarExportView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request, trip_id):
        user = request.user if request.user.is_authenticated else None
        if user is None:
            token = request.query_params.get("token")
            user_from_token = _get_user_from_token(token)
            if not user_from_token:
                raise PermissionDenied("Authentication required.")
            user = user_from_token

        trip = _get_trip_or_404(trip_id)
        _require_member_for_user(user, trip)

        items = (
            ItineraryItem.objects.filter(trip=trip)
            .order_by("date", "start_time", "sort_order")
            .all()
        )
        now = timezone.now()
        lines = [
            "BEGIN:VCALENDAR",
            "VERSION:2.0",
            "PRODID:-//Smart Trip Planner//EN",
            "CALSCALE:GREGORIAN",
        ]

        for item in items:
            if item.date is None:
                continue
            uid = f"{item.id}@smart-trip-planner"
            lines.append("BEGIN:VEVENT")
            lines.append(f"UID:{uid}")
            lines.append(f"DTSTAMP:{now.strftime('%Y%m%dT%H%M%SZ')}")
            if item.start_time or item.end_time:
                start_time = item.start_time or item.end_time
                end_time = item.end_time or item.start_time
                start_dt = timezone.make_aware(
                    datetime.combine(item.date, start_time),
                    timezone=timezone.get_current_timezone(),
                )
                end_dt = timezone.make_aware(
                    datetime.combine(item.date, end_time),
                    timezone=timezone.get_current_timezone(),
                )
                lines.append(f"DTSTART:{start_dt.astimezone(dt_timezone.utc).strftime('%Y%m%dT%H%M%SZ')}")
                lines.append(f"DTEND:{end_dt.astimezone(dt_timezone.utc).strftime('%Y%m%dT%H%M%SZ')}")
            else:
                lines.append(f"DTSTART;VALUE=DATE:{item.date.strftime('%Y%m%d')}")

            summary = item.title.replace("\n", " ").strip()
            lines.append(f"SUMMARY:{summary}")
            if item.location:
                lines.append(f"LOCATION:{item.location.replace('\n', ' ').replace('\r', ' ').strip()}")
            if item.notes:
                lines.append(f"DESCRIPTION:{item.notes.replace('\n', ' ').replace('\r', ' ').strip()}")
            lines.append("END:VEVENT")

        lines.append("END:VCALENDAR")
        content = "\r\n".join(lines)
        response = HttpResponse(content, content_type="text/calendar; charset=utf-8")
        response["Content-Disposition"] = f'attachment; filename="trip-{trip_id}.ics"'
        return response


class TripExpensesView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, trip_id):
        trip = _get_trip_or_404(trip_id)
        _require_member(request, trip)
        expenses = (
            Expense.objects.filter(trip=trip)
            .select_related("paid_by", "created_by")
            .prefetch_related("splits__user")
            .order_by("-created_at")
        )
        return Response(ExpenseSerializer(expenses, many=True).data)

    def post(self, request, trip_id):
        trip = _get_trip_or_404(trip_id)
        member = _require_member(request, trip)
        if not is_editor_or_owner(member):
            raise PermissionDenied("Insufficient permissions.")

        serializer = ExpenseCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        amount = data["amount"]
        currency = data.get("currency") or "USD"
        paid_by_id = data.get("paid_by") or request.user.id

        participant_ids = data.get("participant_ids")
        splits_data = data.get("splits")

        if splits_data:
            participant_ids = [split["user_id"] for split in splits_data]

        members = TripMember.objects.filter(
            trip=trip,
            status=TripStatus.ACTIVE,
        ).select_related("user")

        member_ids = {member.user_id for member in members}
        if participant_ids:
            missing = [pid for pid in participant_ids if pid not in member_ids]
            if missing:
                raise ValidationError("Participants must be trip members.")
        else:
            participant_ids = list(member_ids)

        if paid_by_id not in member_ids:
            raise ValidationError("paid_by must be a trip member.")

        with transaction.atomic():
            expense = Expense.objects.create(
                trip=trip,
                title=data["title"],
                amount=amount,
                currency=currency,
                paid_by_id=paid_by_id,
                created_by=request.user,
            )

            if splits_data:
                total_split = sum((split["amount"] for split in splits_data), Decimal("0"))
                if total_split != amount:
                    raise ValidationError("Split amounts must equal total amount.")
                splits = [
                    ExpenseSplit(expense=expense, user_id=split["user_id"], amount=split["amount"])
                    for split in splits_data
                ]
            else:
                count = len(participant_ids)
                if count == 0:
                    raise ValidationError("Participants required.")
                quant = Decimal("0.01")
                share = (amount / count).quantize(quant, rounding=ROUND_HALF_UP)
                splits = []
                for idx, user_id in enumerate(participant_ids):
                    split_amount = share
                    if idx == count - 1:
                        split_amount = amount - share * (count - 1)
                    splits.append(ExpenseSplit(expense=expense, user_id=user_id, amount=split_amount))

            ExpenseSplit.objects.bulk_create(splits)

        expense = (
            Expense.objects.filter(id=expense.id)
            .select_related("paid_by", "created_by")
            .prefetch_related("splits__user")
            .get()
        )
        return Response(ExpenseSerializer(expense).data, status=status.HTTP_201_CREATED)


class TripExpenseSummaryView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, trip_id):
        trip = _get_trip_or_404(trip_id)
        _require_member(request, trip)

        members = (
            TripMember.objects.filter(trip=trip, status=TripStatus.ACTIVE)
            .select_related("user")
            .order_by("created_at")
        )
        paid_map = {
            row["paid_by_id"]: row["total"]
            for row in Expense.objects.filter(trip=trip)
            .values("paid_by_id")
            .annotate(total=Sum("amount"))
        }
        owed_map = {
            row["user_id"]: row["total"]
            for row in ExpenseSplit.objects.filter(expense__trip=trip)
            .values("user_id")
            .annotate(total=Sum("amount"))
        }

        summary = []
        for member in members:
            paid = paid_map.get(member.user_id, Decimal("0.00"))
            owed = owed_map.get(member.user_id, Decimal("0.00"))
            net = paid - owed
            summary.append(
                {
                    "user": {
                        "id": member.user_id,
                        "email": member.user.email,
                        "name": member.user.name or "",
                    },
                    "paid": paid,
                    "owed": owed,
                    "net": net,
                }
            )

        serializer = ExpenseSummarySerializer(summary, many=True)
        return Response(serializer.data)


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
