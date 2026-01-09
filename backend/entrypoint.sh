#!/bin/sh
set -e

if [ "$#" -eq 0 ]; then
  python manage.py migrate --noinput
  exec gunicorn config.wsgi:application --bind 0.0.0.0:8000
fi

exec "$@"
