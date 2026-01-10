import logging
from urllib.parse import parse_qs

from channels.db import database_sync_to_async
from channels.generic.websocket import AsyncJsonWebsocketConsumer

logger = logging.getLogger("chat")


class TripChatConsumer(AsyncJsonWebsocketConsumer):
    async def connect(self):
        self.trip_id = self.scope["url_route"]["kwargs"]["trip_id"]
        self.group_name = f"trip_{self.trip_id}"

        await self.accept()

        token = self._get_token()
        if not token:
            await self._send_error("AUTH_REQUIRED", "Missing token.")
            await self.close()
            return

        user = await self._get_user_from_token(token)
        if user is None:
            await self._send_error("AUTH_INVALID", "Invalid token.")
            await self.close()
            return

        trip = await self._get_trip(self.trip_id)
        if trip is None:
            await self._send_error("NOT_FOUND", "Trip not found.")
            await self.close()
            return

        is_member = await self._is_member(user, trip)
        if not is_member:
            await self._send_error("FORBIDDEN", "Not a trip member.")
            await self.close()
            return

        self.user = user
        self.trip = trip

        await self.channel_layer.group_add(self.group_name, self.channel_name)
        logger.info(
            "ws connect trip=%s",
            self.trip_id,
            extra={"user_id": str(self.user.id)},
        )

    async def disconnect(self, close_code):
        if hasattr(self, "group_name"):
            await self.channel_layer.group_discard(self.group_name, self.channel_name)
        if hasattr(self, "user"):
            logger.info(
                "ws disconnect trip=%s",
                getattr(self, "trip_id", "unknown"),
                extra={"user_id": str(self.user.id)},
            )

    async def receive_json(self, content, **kwargs):
        if not hasattr(self, "user") or not hasattr(self, "trip"):
            await self._send_error("AUTH_REQUIRED", "Authentication required.")
            return

        message_type = content.get("type")
        if message_type != "message":
            await self._send_error("INVALID_TYPE", "Unsupported message type.")
            return

        text = (content.get("content") or "").strip()
        encrypted_content = (content.get("encrypted_content") or "").strip()
        if not text and not encrypted_content:
            await self._send_error("INVALID_MESSAGE", "Content is required.")
            return

        encryption_version = content.get("encryption_version")
        if encrypted_content:
            if encryption_version is None:
                encryption_version = 1
            else:
                try:
                    encryption_version = int(encryption_version)
                except (TypeError, ValueError):
                    await self._send_error("INVALID_MESSAGE", "encryption_version must be an integer.")
                    return
        else:
            encryption_version = None

        client_id = content.get("client_id")
        message, created = await self._create_message(text, encrypted_content, encryption_version, client_id)
        from .serializers import ChatMessageSerializer

        payload = ChatMessageSerializer(message).data

        if created:
            await self.channel_layer.group_send(
                self.group_name,
                {"type": "chat.message", "message": payload},
            )
        else:
            await self.send_json({"type": "message", "message": payload})

    async def chat_message(self, event):
        await self.send_json({"type": "message", "message": event["message"]})

    def _get_token(self):
        query_string = self.scope.get("query_string", b"").decode("utf-8")
        params = parse_qs(query_string)
        return params.get("token", [None])[0]

    async def _send_error(self, code, message):
        await self.send_json(
            {
                "type": "error",
                "error": {"code": code, "message": message},
            }
        )

    @database_sync_to_async
    def _get_user_from_token(self, token):
        from django.contrib.auth import get_user_model
        from rest_framework_simplejwt.exceptions import TokenError
        from rest_framework_simplejwt.tokens import AccessToken

        try:
            access = AccessToken(token)
        except TokenError:
            return None
        user_id = access.get("user_id")
        if not user_id:
            return None
        User = get_user_model()
        return User.objects.filter(id=user_id, is_active=True).first()

    @database_sync_to_async
    def _get_trip(self, trip_id):
        from .models import Trip

        return Trip.objects.filter(id=trip_id).first()

    @database_sync_to_async
    def _is_member(self, user, trip):
        from .models import TripMember, TripStatus

        return TripMember.objects.filter(
            trip=trip,
            user=user,
            status=TripStatus.ACTIVE,
        ).exists()

    @database_sync_to_async
    def _create_message(self, text, encrypted_content, encryption_version, client_id):
        from .models import ChatMessage

        if client_id:
            existing = (
                ChatMessage.objects.filter(
                    trip=self.trip,
                    sender=self.user,
                    client_id=client_id,
                )
                .select_related("sender")
                .first()
            )
            if existing:
                return existing, False

        message = ChatMessage.objects.create(
            trip=self.trip,
            sender=self.user,
            content=text or "",
            encrypted_content=encrypted_content or None,
            encryption_version=encryption_version,
            client_id=client_id,
        )
        message = ChatMessage.objects.select_related("sender").get(id=message.id)
        return message, True
