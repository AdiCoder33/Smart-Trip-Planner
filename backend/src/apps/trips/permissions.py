from rest_framework import permissions

from .models import TripMember, TripRole, TripStatus


def get_trip_member(user, trip):
    if not user or not user.is_authenticated:
        return None
    return TripMember.objects.filter(
        trip=trip,
        user=user,
        status=TripStatus.ACTIVE,
    ).first()


def is_owner(member):
    return member and member.role == TripRole.OWNER


def is_editor_or_owner(member):
    return member and member.role in (TripRole.OWNER, TripRole.EDITOR)


class TripPermission(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        member = get_trip_member(request.user, obj)

        if member is None:
            return False

        if request.method in permissions.SAFE_METHODS:
            return True

        if request.method in ("PUT", "PATCH"):
            return is_editor_or_owner(member)

        if request.method == "DELETE":
            return is_owner(member)

        return False


class TripMemberPermission(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        member = get_trip_member(request.user, obj.trip)
        if member is None:
            return False
        if request.method in permissions.SAFE_METHODS:
            return True
        return is_editor_or_owner(member)


class TripOwnerPermission(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        member = get_trip_member(request.user, obj.trip)
        return is_owner(member)

    def has_permission(self, request, view):
        trip = getattr(view, "trip", None)
        if trip is None:
            return request.user and request.user.is_authenticated
        member = get_trip_member(request.user, trip)
        return is_owner(member)
