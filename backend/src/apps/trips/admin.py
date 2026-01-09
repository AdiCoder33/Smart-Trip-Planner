from django.contrib import admin

from .models import Trip, TripMember


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
