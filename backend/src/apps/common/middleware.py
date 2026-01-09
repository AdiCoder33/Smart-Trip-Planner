import logging
import time
import uuid

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
            extra={"request_id": getattr(request, "request_id", "n/a")},
        )
        return response
