from django.urls import path
from rest_framework.routers import DefaultRouter

from .views import (
    InviteAcceptView,
    InviteRevokeView,
    ItineraryItemDetailView,
    PollDetailView,
    PollVoteView,
    TripInvitesView,
    TripItineraryReorderView,
    TripItineraryView,
    TripMembersView,
    TripPollsView,
    TripViewSet,
)

router = DefaultRouter(trailing_slash=False)
router.register("trips", TripViewSet, basename="trips")

urlpatterns = [
    path("trips/<uuid:trip_id>/itinerary", TripItineraryView.as_view(), name="trip-itinerary"),
    path(
        "trips/<uuid:trip_id>/itinerary/reorder",
        TripItineraryReorderView.as_view(),
        name="trip-itinerary-reorder",
    ),
    path("itinerary/<uuid:item_id>", ItineraryItemDetailView.as_view(), name="itinerary-item-detail"),
    path("trips/<uuid:trip_id>/invites", TripInvitesView.as_view(), name="trip-invites"),
    path("invites/accept", InviteAcceptView.as_view(), name="invite-accept"),
    path("invites/revoke", InviteRevokeView.as_view(), name="invite-revoke"),
    path("trips/<uuid:trip_id>/members", TripMembersView.as_view(), name="trip-members"),
    path("trips/<uuid:trip_id>/polls", TripPollsView.as_view(), name="trip-polls"),
    path("polls/<uuid:poll_id>", PollDetailView.as_view(), name="poll-detail"),
    path("polls/<uuid:poll_id>/vote", PollVoteView.as_view(), name="poll-vote"),
] + router.urls
