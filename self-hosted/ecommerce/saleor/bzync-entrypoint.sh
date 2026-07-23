#!/bin/sh
# Saleor's own image has no auto-migration and no bundled process
# supervisor — the reference saleor-platform docker-compose runs
# migrations as a separate one-off step and the Celery worker as a
# completely separate container. This template is a single container per
# app, so this wraps all three: migrate once, then run the API server and
# the Celery worker (bundled with -B for the beat scheduler, so no fourth
# process is needed) backgrounded together.
set -e

python manage.py migrate --noinput

if [ -n "$DJANGO_SUPERUSER_EMAIL" ] && [ -n "$DJANGO_SUPERUSER_PASSWORD" ]; then
  python manage.py createsuperuser --noinput || true
fi

celery -A saleor --app=saleor.celeryconf:app worker --loglevel=info -B &
WORKER_PID=$!

uvicorn saleor.asgi:application --host=0.0.0.0 --port=8000 --workers=2 \
  --lifespan=auto --ws=none --no-server-header --no-access-log \
  --timeout-keep-alive=35 --timeout-graceful-shutdown=30 --limit-max-requests=10000 &
MAIN_PID=$!

trap 'kill -TERM "$MAIN_PID" "$WORKER_PID" 2>/dev/null' TERM INT
wait "$MAIN_PID"
