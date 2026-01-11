from django.urls import path
from rest_framework.routers import DefaultRouter

from .views import (
    TripChatKeyView,
    InviteAcceptView,
    InviteRevokeView,
    ItineraryItemDetailView,
    PollDetailView,
    PollVoteView,
    SentInvitesView,
    TripCalendarExportView,
    TripExpensesView,
    TripExpenseSummaryView,
    TripInvitesView,
    TripItineraryReorderView,
    TripItineraryView,
    TripChatMessagesView,
    TripMembersView,
    TripPollsView,
    TripUserSearchView,
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
    path(
        "trips/<uuid:trip_id>/chat/messages",
        TripChatMessagesView.as_view(),
        name="trip-chat-messages",
    ),
    path("trips/<uuid:trip_id>/chat/key", TripChatKeyView.as_view(), name="trip-chat-key"),
    path("trips/<uuid:trip_id>/calendar", TripCalendarExportView.as_view(), name="trip-calendar-export"),
    path("trips/<uuid:trip_id>/expenses", TripExpensesView.as_view(), name="trip-expenses"),
    path(
        "trips/<uuid:trip_id>/expenses/summary",
        TripExpenseSummaryView.as_view(),
        name="trip-expenses-summary",
    ),
    path("invites/accept", InviteAcceptView.as_view(), name="invite-accept"),
    path("invites/revoke", InviteRevokeView.as_view(), name="invite-revoke"),
    path("invites/sent", SentInvitesView.as_view(), name="invites-sent"),
    path("trips/<uuid:trip_id>/members", TripMembersView.as_view(), name="trip-members"),
    path("trips/<uuid:trip_id>/user-search", TripUserSearchView.as_view(), name="trip-user-search"),
    path("trips/<uuid:trip_id>/polls", TripPollsView.as_view(), name="trip-polls"),
    path("polls/<uuid:poll_id>", PollDetailView.as_view(), name="poll-detail"),
    path("polls/<uuid:poll_id>/vote", PollVoteView.as_view(), name="poll-vote"),
] + router.urls
