#!/bin/sh
# Wraps valkey-server with a minimal HTTP status endpoint on port 3000.
# Valkey speaks the Redis protocol on 6379, not HTTP — without this, any
# browser visit to this project's public dashboard URL hits Traefik trying
# (and failing) to speak HTTP to 6379, showing a bare "Bad Gateway" with no
# indication of whether Valkey itself is actually up. This gives that same
# URL a real answer instead: a live PING against the real valkey-server
# process, not just a static "ok".
#
# EXPOSE 3000 in the Dockerfile is lower than 6379, so imageExposedPort()
# (compute's startAppContainer) picks 3000 for ingress/health checks
# automatically — Valkey itself is still reachable from other projects on
# the internal network at its real port, 6379, same as before.
set -e

valkey-server --requirepass "$VALKEY_PASSWORD" --appendonly yes &
VALKEY_PID=$!

serve_status() {
  while true; do
    if valkey-cli -a "$VALKEY_PASSWORD" --no-auth-warning -h 127.0.0.1 ping 2>/dev/null | grep -q PONG; then
      status_line='HTTP/1.1 200 OK'
      body='{"status":"ok","service":"valkey","valkey":"reachable"}'
    else
      status_line='HTTP/1.1 503 Service Unavailable'
      body='{"status":"error","service":"valkey","valkey":"unreachable"}'
    fi
    printf '%s\r\nContent-Type: application/json\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s' \
      "$status_line" "${#body}" "$body" | nc -l -p 3000 >/dev/null 2>&1 || true
  done
}
serve_status &
STATUS_PID=$!

trap 'kill -TERM "$VALKEY_PID" "$STATUS_PID" 2>/dev/null' TERM INT
wait "$VALKEY_PID"
