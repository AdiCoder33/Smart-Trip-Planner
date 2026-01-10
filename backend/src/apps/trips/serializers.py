from rest_framework import serializers

from .models import ChatMessage, ItineraryItem, Poll, PollOption, Trip, TripInvite, TripMember, TripRole


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


class MemberUserSerializer(serializers.Serializer):
    id = serializers.UUIDField()
    email = serializers.EmailField()
    name = serializers.CharField(allow_blank=True, required=False)


class TripMemberSerializer(serializers.ModelSerializer):
    user = MemberUserSerializer(source="user")

    class Meta:
        model = TripMember
        fields = ("id", "user", "role", "status", "created_at")
        read_only_fields = fields


class ChatSenderSerializer(serializers.Serializer):
    id = serializers.UUIDField()
    name = serializers.CharField(allow_blank=True, required=False)


class ChatMessageSerializer(serializers.ModelSerializer):
    trip_id = serializers.UUIDField(source="trip_id", read_only=True)
    sender = ChatSenderSerializer(source="sender", read_only=True)

    class Meta:
        model = ChatMessage
        fields = (
            "id",
            "trip_id",
            "sender",
            "content",
            "client_id",
            "created_at",
        )
        read_only_fields = fields


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
