#!/bin/sh
set -e

if [ "$#" -eq 0 ]; then
  python manage.py migrate --noinput
  python manage.py collectstatic --noinput
  exec gunicorn config.asgi:application \
    --bind 0.0.0.0:8000 \
    --worker-class uvicorn.workers.UvicornWorker
fi

exec "$@"
