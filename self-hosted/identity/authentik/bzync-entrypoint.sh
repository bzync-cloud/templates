#!/bin/sh
# authentik ships as two roles from the same image — server (HTTP/API) and
# worker (background tasks: emails, sync, flow execution) — normally run as
# two separate containers in upstream's docker-compose. This template is a
# single container per app, so both roles run here, backgrounded, sharing
# the same Postgres. If the worker dies, background tasks (and some flows)
# stop silently while the server keeps answering HTTP — check `docker logs`
# if things seem to hang rather than error outright.
set -e

ak server &
SERVER_PID=$!

ak worker &
WORKER_PID=$!

trap 'kill -TERM "$SERVER_PID" "$WORKER_PID" 2>/dev/null' TERM INT
wait "$SERVER_PID"
