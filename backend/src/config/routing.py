from django.urls import path

from apps.trips.consumers import TripChatConsumer

websocket_urlpatterns = [
    path("ws/trips/<uuid:trip_id>/chat/", TripChatConsumer.as_asgi()),
]
