from django.db import transaction
from rest_framework import permissions, viewsets

from .models import Trip, TripMember, TripRole, TripStatus
from .permissions import TripPermission
from .serializers import TripSerializer


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
