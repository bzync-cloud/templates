#!/bin/sh
# Wraps meilisearch with a minimal HTTP JSON status endpoint on port 3000,
# same pattern as the redis/garage/seaweedfs/typesense templates'
# bzync-entrypoint.sh — added here for consistency across every data-store
# template, even though Meilisearch's real API port (7700) already answers
# an unauthenticated GET / with a native 200 JSON status
# (`{"status":"Meilisearch is running"}`, confirmed by testing) and
# strictly speaking doesn't need a wrapper the way redis/garage/seaweedfs/
# typesense do (their real ports 403/404 on GET /).
#
# EXPOSE 3000 in the Dockerfile is lower than 7700, so imageExposedPort()
# (compute's startAppContainer) picks 3000 for ingress/health checks
# automatically — the real API is still reachable from other projects on
# the internal network at its real port, 7700, same as before.
set -e

/bin/meilisearch &
MEILI_PID=$!

serve_status() {
  while true; do
    if wget -qO- http://127.0.0.1:7700/health 2>/dev/null | grep -q '"available"'; then
      status_line='HTTP/1.1 200 OK'
      body='{"status":"ok","service":"meilisearch","meilisearch":"reachable"}'
    else
      status_line='HTTP/1.1 503 Service Unavailable'
      body='{"status":"error","service":"meilisearch","meilisearch":"unreachable"}'
    fi
    printf '%s\r\nContent-Type: application/json\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s' \
      "$status_line" "${#body}" "$body" | nc -l -p 3000 >/dev/null 2>&1 || true
  done
}
serve_status &
STATUS_PID=$!

trap 'kill -TERM "$MEILI_PID" "$STATUS_PID" 2>/dev/null' TERM INT
wait "$MEILI_PID"
