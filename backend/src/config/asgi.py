import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]
if str(BASE_DIR) not in os.sys.path:
    os.sys.path.insert(0, str(BASE_DIR))

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings.dev")

import django  # noqa: E402

django.setup()

from django.core.asgi import get_asgi_application  # noqa: E402

django_asgi_app = get_asgi_application()

from channels.routing import ProtocolTypeRouter, URLRouter  # noqa: E402
from channels.security.websocket import AllowedHostsOriginValidator  # noqa: E402
from django.conf import settings  # noqa: E402

from . import routing  # noqa: E402

websocket_app = URLRouter(routing.websocket_urlpatterns)
if not settings.DEBUG:
    websocket_app = AllowedHostsOriginValidator(websocket_app)

application = ProtocolTypeRouter(
    {
        "http": django_asgi_app,
        "websocket": websocket_app,
    }
)
