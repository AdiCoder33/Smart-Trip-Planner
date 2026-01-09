from rest_framework import status
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response
from rest_framework.views import exception_handler as drf_exception_handler


def _extract_message(data):
    if isinstance(data, dict):
        if "detail" in data:
            return data.get("detail"), None
        return "Validation error", data
    if isinstance(data, list):
        return "Validation error", data
    return str(data), None


def custom_exception_handler(exc, context):
    request = context.get("request")
    request_id = getattr(request, "request_id", "n/a")
    response = drf_exception_handler(exc, context)

    if response is None:
        return Response(
            {
                "error": {
                    "code": "SERVER_ERROR",
                    "message": "Unexpected server error",
                    "request_id": request_id,
                }
            },
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )

    code = getattr(exc, "default_code", "error")
    if isinstance(exc, ValidationError):
        code = "validation_error"

    message, details = _extract_message(response.data)

    error_payload = {
        "code": str(code).upper(),
        "message": message,
        "request_id": request_id,
    }
    if details is not None:
        error_payload["details"] = details

    return Response({"error": error_payload}, status=response.status_code)
