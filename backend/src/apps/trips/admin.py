from django.contrib import admin

from .models import ItineraryItem, Poll, PollOption, Trip, TripInvite, TripMember, Vote


@admin.register(Trip)
class TripAdmin(admin.ModelAdmin):
    list_display = ("title", "destination", "created_by", "created_at")
    search_fields = ("title", "destination", "created_by__email")
    list_filter = ("created_at",)


@admin.register(TripMember)
class TripMemberAdmin(admin.ModelAdmin):
    list_display = ("trip", "user", "role", "status")
    list_filter = ("role", "status")
    search_fields = ("trip__title", "user__email")


@admin.register(ItineraryItem)
class ItineraryItemAdmin(admin.ModelAdmin):
    list_display = ("trip", "title", "date", "sort_order", "created_by")
    list_filter = ("date",)
    search_fields = ("title", "trip__title", "created_by__email")


@admin.register(TripInvite)
class TripInviteAdmin(admin.ModelAdmin):
    list_display = ("trip", "email", "role", "status", "invited_by", "expires_at")
    list_filter = ("status", "role")
    search_fields = ("email", "trip__title", "invited_by__email")


@admin.register(Poll)
class PollAdmin(admin.ModelAdmin):
    list_display = ("trip", "question", "is_active", "created_by", "created_at")
    list_filter = ("is_active",)
    search_fields = ("question", "trip__title", "created_by__email")


@admin.register(PollOption)
class PollOptionAdmin(admin.ModelAdmin):
    list_display = ("poll", "text")
    search_fields = ("text", "poll__question")


@admin.register(Vote)
class VoteAdmin(admin.ModelAdmin):
    list_display = ("poll", "option", "user", "created_at")
    search_fields = ("poll__question", "option__text", "user__email")
