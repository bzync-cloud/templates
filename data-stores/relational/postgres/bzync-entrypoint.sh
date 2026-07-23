#!/bin/sh
# Wraps the upstream docker-entrypoint.sh with a minimal HTTP status
# endpoint on port 3000. Postgres speaks its own binary protocol on 5432,
# not HTTP, so visiting this project's public dashboard URL directly in a
# browser used to just show Traefik's bare "Bad Gateway" — Postgres was
# fine, there was just nothing that could answer an HTTP request. This
# gives that same URL a real answer instead: a live `pg_isready` against
# the real postgres process, not just a static response.
#
# EXPOSE 3000 in the Dockerfile is lower than 5432, so imageExposedPort()
# (compute's startAppContainer) picks 3000 for ingress/health checks
# automatically — Postgres itself is still reachable from other projects on
# the internal network at its real port, 5432, same as before.
set -e

docker-entrypoint.sh postgres &
MAIN_PID=$!

serve_status() {
  while true; do
    if pg_isready -U "$POSTGRES_USER" -h 127.0.0.1 >/dev/null 2>&1; then
      status_line='HTTP/1.1 200 OK'
      body='{"status":"ok","service":"postgres","postgres":"reachable"}'
    else
      status_line='HTTP/1.1 503 Service Unavailable'
      body='{"status":"error","service":"postgres","postgres":"unreachable"}'
    fi
    printf '%s\r\nContent-Type: application/json\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s' \
      "$status_line" "${#body}" "$body" | nc -l -p 3000 >/dev/null 2>&1 || true
  done
}
serve_status &
STATUS_PID=$!

trap 'kill -TERM "$MAIN_PID" "$STATUS_PID" 2>/dev/null' TERM INT
wait "$MAIN_PID"
