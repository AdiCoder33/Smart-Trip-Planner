from rest_framework import permissions

from .models import TripMember, TripRole, TripStatus


class TripPermission(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        member = TripMember.objects.filter(
            trip=obj,
            user=request.user,
            status=TripStatus.ACTIVE,
        ).first()

        if member is None:
            return False

        if request.method in permissions.SAFE_METHODS:
            return True

        if request.method in ("PUT", "PATCH"):
            return member.role in (TripRole.OWNER, TripRole.EDITOR)

        if request.method == "DELETE":
            return member.role == TripRole.OWNER

        return False
