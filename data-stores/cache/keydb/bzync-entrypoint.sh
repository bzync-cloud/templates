#!/bin/sh
# Wraps keydb-server with a minimal HTTP status endpoint on port 3000.
# KeyDB speaks the Redis protocol on 6379, not HTTP — without this, any
# browser visit to this project's public dashboard URL hits Traefik trying
# (and failing) to speak HTTP to 6379, showing a bare "Bad Gateway" with no
# indication of whether KeyDB itself is actually up. This gives that same
# URL a real answer instead: a live PING against the real keydb-server
# process, not just a static "ok".
#
# EXPOSE 3000 in the Dockerfile is lower than 6379, so imageExposedPort()
# (compute's startAppContainer) picks 3000 for ingress/health checks
# automatically — KeyDB itself is still reachable from other projects on
# the internal network at its real port, 6379, same as before.
set -e

keydb-server --requirepass "$KEYDB_PASSWORD" --appendonly yes --server-threads 2 &
KEYDB_PID=$!

serve_status() {
  while true; do
    if keydb-cli -a "$KEYDB_PASSWORD" --no-auth-warning -h 127.0.0.1 ping 2>/dev/null | grep -q PONG; then
      status_line='HTTP/1.1 200 OK'
      body='{"status":"ok","service":"keydb","keydb":"reachable"}'
    else
      status_line='HTTP/1.1 503 Service Unavailable'
      body='{"status":"error","service":"keydb","keydb":"unreachable"}'
    fi
    printf '%s\r\nContent-Type: application/json\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s' \
      "$status_line" "${#body}" "$body" | nc -l -p 3000 >/dev/null 2>&1 || true
  done
}
serve_status &
STATUS_PID=$!

trap 'kill -TERM "$KEYDB_PID" "$STATUS_PID" 2>/dev/null' TERM INT
wait "$KEYDB_PID"
