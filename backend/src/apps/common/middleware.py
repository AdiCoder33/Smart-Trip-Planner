import logging
import time
import uuid

from django.conf import settings
from django.core.cache import cache
from django.http import JsonResponse
from django.utils.deprecation import MiddlewareMixin

logger = logging.getLogger("request")


class RequestIdMiddleware(MiddlewareMixin):
    def process_request(self, request):
        request.request_id = request.META.get("HTTP_X_REQUEST_ID") or str(uuid.uuid4())

    def process_response(self, request, response):
        request_id = getattr(request, "request_id", None)
        if request_id:
            response["X-Request-ID"] = request_id
        return response


class RateLimitMiddleware(MiddlewareMixin):
    def process_request(self, request):
        if not request.path.startswith("/api/"):
            return None

        user = getattr(request, "user", None)
        is_authenticated = bool(user and user.is_authenticated)
        limit = (
            settings.RATE_LIMIT_USER_PER_MINUTE
            if is_authenticated
            else settings.RATE_LIMIT_ANON_PER_MINUTE
        )
        identifier = str(user.id) if is_authenticated else request.META.get("REMOTE_ADDR", "unknown")
        window = int(time.time() // 60)
        key = f"rl:{identifier}:{window}"

        current = cache.get(key)
        if current is None:
            cache.set(key, 1, timeout=60)
            return None

        if current >= limit:
            request_id = getattr(request, "request_id", "n/a")
            return JsonResponse(
                {
                    "error": {
                        "code": "RATE_LIMITED",
                        "message": "Rate limit exceeded. Please try again later.",
                        "request_id": request_id,
                    }
                },
                status=429,
            )

        try:
            cache.incr(key)
        except ValueError:
            cache.set(key, 1, timeout=60)
        return None


class RequestLoggingMiddleware(MiddlewareMixin):
    def process_request(self, request):
        request._start_time = time.monotonic()

    def process_response(self, request, response):
        start = getattr(request, "_start_time", None)
        latency_ms = None
        if start is not None:
            latency_ms = int((time.monotonic() - start) * 1000)

        logger.info(
            "%s %s %s %sms",
            request.method,
            request.get_full_path(),
            response.status_code,
            latency_ms if latency_ms is not None else "-",
            extra={
                "request_id": getattr(request, "request_id", "n/a"),
                "user_id": getattr(request.user, "id", "anonymous")
                if getattr(request, "user", None) and request.user.is_authenticated
                else "anonymous",
            },
        )
        return response
