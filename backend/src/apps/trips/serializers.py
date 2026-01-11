from rest_framework import serializers

from .models import (
    ChatMessage,
    Expense,
    ExpenseSplit,
    ItineraryItem,
    Poll,
    PollOption,
    Trip,
    TripInvite,
    TripMember,
    TripRole,
)


class TripSerializer(serializers.ModelSerializer):
    class Meta:
        model = Trip
        fields = (
            "id",
            "title",
            "destination",
            "start_date",
            "end_date",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "created_at", "updated_at")


class ItineraryItemSerializer(serializers.ModelSerializer):
    created_by = serializers.UUIDField(source="created_by_id", read_only=True)

    class Meta:
        model = ItineraryItem
        fields = (
            "id",
            "title",
            "notes",
            "location",
            "start_time",
            "end_time",
            "date",
            "sort_order",
            "created_by",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "sort_order", "created_by", "created_at", "updated_at")


class ItineraryReorderItemSerializer(serializers.Serializer):
    id = serializers.UUIDField()
    sort_order = serializers.IntegerField(min_value=0)


class ItineraryReorderSerializer(serializers.Serializer):
    items = ItineraryReorderItemSerializer(many=True)


class TripInviteSerializer(serializers.ModelSerializer):
    invited_by = serializers.UUIDField(source="invited_by_id", read_only=True)

    class Meta:
        model = TripInvite
        fields = ("id", "email", "role", "status", "invited_by", "created_at", "expires_at")
        read_only_fields = fields


class TripInviteCreateSerializer(serializers.Serializer):
    email = serializers.EmailField()
    role = serializers.ChoiceField(choices=[TripRole.EDITOR, TripRole.VIEWER])


class InviteAcceptSerializer(serializers.Serializer):
    token = serializers.CharField()


class InviteRevokeSerializer(serializers.Serializer):
    invite_id = serializers.UUIDField()


class InviteIdSerializer(serializers.Serializer):
    invite_id = serializers.UUIDField()


class TripInfoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Trip
        fields = ("id", "title")


class TripInviteSentSerializer(serializers.ModelSerializer):
    invited_by = serializers.UUIDField(source="invited_by_id", read_only=True)
    trip = TripInfoSerializer(read_only=True)

    class Meta:
        model = TripInvite
        fields = (
            "id",
            "email",
            "role",
            "status",
            "invited_by",
            "trip",
            "created_at",
            "expires_at",
        )
        read_only_fields = fields


class MemberUserSerializer(serializers.Serializer):
    id = serializers.UUIDField()
    email = serializers.EmailField()
    name = serializers.CharField(allow_blank=True, required=False)


class TripMemberSerializer(serializers.ModelSerializer):
    user = MemberUserSerializer(read_only=True)

    class Meta:
        model = TripMember
        fields = ("id", "user", "role", "status", "created_at")
        read_only_fields = fields


class UserLookupSerializer(serializers.Serializer):
    id = serializers.UUIDField()
    email = serializers.EmailField()
    name = serializers.CharField(allow_blank=True, required=False)


class ChatSenderSerializer(serializers.Serializer):
    id = serializers.UUIDField()
    name = serializers.CharField(allow_blank=True, required=False)


class ChatMessageSerializer(serializers.ModelSerializer):
    trip_id = serializers.UUIDField(read_only=True)
    sender = ChatSenderSerializer(read_only=True)

    class Meta:
        model = ChatMessage
        fields = (
            "id",
            "trip_id",
            "sender",
            "content",
            "encrypted_content",
            "encryption_version",
            "client_id",
            "created_at",
        )
        read_only_fields = fields


class ExpenseSplitSerializer(serializers.ModelSerializer):
    user = MemberUserSerializer(read_only=True)

    class Meta:
        model = ExpenseSplit
        fields = ("id", "user", "amount")
        read_only_fields = fields


class ExpenseSerializer(serializers.ModelSerializer):
    trip_id = serializers.UUIDField(read_only=True)
    paid_by = MemberUserSerializer(read_only=True)
    created_by = MemberUserSerializer(read_only=True)
    splits = ExpenseSplitSerializer(many=True, read_only=True)

    class Meta:
        model = Expense
        fields = (
            "id",
            "trip_id",
            "title",
            "amount",
            "currency",
            "paid_by",
            "created_by",
            "splits",
            "created_at",
        )
        read_only_fields = fields


class ExpenseSplitInputSerializer(serializers.Serializer):
    user_id = serializers.UUIDField()
    amount = serializers.DecimalField(max_digits=10, decimal_places=2)


class ExpenseCreateSerializer(serializers.Serializer):
    title = serializers.CharField()
    amount = serializers.DecimalField(max_digits=10, decimal_places=2)
    currency = serializers.CharField(max_length=3, required=False)
    paid_by = serializers.UUIDField(required=False)
    participant_ids = serializers.ListField(child=serializers.UUIDField(), required=False)
    splits = ExpenseSplitInputSerializer(many=True, required=False)


class ExpenseSummarySerializer(serializers.Serializer):
    user = MemberUserSerializer()
    paid = serializers.DecimalField(max_digits=10, decimal_places=2)
    owed = serializers.DecimalField(max_digits=10, decimal_places=2)
    net = serializers.DecimalField(max_digits=10, decimal_places=2)


class PollOptionSerializer(serializers.ModelSerializer):
    vote_count = serializers.IntegerField(read_only=True)

    class Meta:
        model = PollOption
        fields = ("id", "text", "vote_count")
        read_only_fields = fields


class PollSerializer(serializers.ModelSerializer):
    options = PollOptionSerializer(many=True, read_only=True)
    user_vote_option_id = serializers.SerializerMethodField()

    class Meta:
        model = Poll
        fields = (
            "id",
            "question",
            "is_active",
            "options",
            "user_vote_option_id",
            "created_at",
            "updated_at",
        )

    def get_user_vote_option_id(self, obj):
        request = self.context.get("request")
        if request is None or not request.user.is_authenticated:
            return None
        vote = next((vote for vote in getattr(obj, "user_votes", [])), None)
        if vote is None:
            vote = obj.votes.filter(user=request.user).first()
        return str(vote.option_id) if vote else None


class PollCreateSerializer(serializers.Serializer):
    question = serializers.CharField()
    options = serializers.ListField(child=serializers.CharField(), min_length=2)


class PollVoteSerializer(serializers.Serializer):
    option_id = serializers.UUIDField()
