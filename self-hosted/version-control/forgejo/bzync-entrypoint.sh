#!/bin/sh
# Wraps the upstream s6 entrypoint so we can auto-create the first admin
# account from FORGEJO_ADMIN_* env vars once the instance is actually up.
# The upstream image has no hook for this — without it there's no way to
# log in until someone execs into the container (see README).
set -e

/usr/bin/entrypoint "$@" &
MAIN_PID=$!
trap 'kill -TERM "$MAIN_PID" 2>/dev/null' TERM INT

if [ -n "$FORGEJO_ADMIN_USERNAME" ] && [ -n "$FORGEJO_ADMIN_PASSWORD" ]; then
  /usr/local/bin/bzync-create-admin.sh &
fi

wait "$MAIN_PID"
