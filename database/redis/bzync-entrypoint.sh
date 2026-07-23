#!/bin/sh
# Wraps redis-server with a minimal HTTP status endpoint on port 3000.
# Redis speaks its own binary protocol on 6379, not HTTP — without this, any
# browser visit to this project's public dashboard URL hits Traefik trying
# (and failing) to speak HTTP to 6379, showing a bare "Bad Gateway" with no
# indication of whether Redis itself is actually up. This gives that same
# URL a real answer instead: a live PING against the real redis-server
# process, not just a static "ok".
#
# EXPOSE 3000 in the Dockerfile is lower than 6379, so imageExposedPort()
# (compute's startAppContainer) picks 3000 for ingress/health checks
# automatically — Redis itself is still reachable from other projects on
# the internal network at its real port, 6379, same as before.
set -e

redis-server --requirepass "$REDIS_PASSWORD" --appendonly yes &
REDIS_PID=$!

serve_status() {
  while true; do
    if redis-cli -a "$REDIS_PASSWORD" --no-auth-warning -h 127.0.0.1 ping 2>/dev/null | grep -q PONG; then
      status_line='HTTP/1.1 200 OK'
      body='{"status":"ok","service":"redis","redis":"reachable"}'
    else
      status_line='HTTP/1.1 503 Service Unavailable'
      body='{"status":"error","service":"redis","redis":"unreachable"}'
    fi
    printf '%s\r\nContent-Type: application/json\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s' \
      "$status_line" "${#body}" "$body" | nc -l -p 3000 >/dev/null 2>&1 || true
  done
}
serve_status &
STATUS_PID=$!

trap 'kill -TERM "$REDIS_PID" "$STATUS_PID" 2>/dev/null' TERM INT
wait "$REDIS_PID"
