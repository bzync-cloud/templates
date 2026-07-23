#!/bin/bash
# Wraps typesense-server with a minimal HTTP JSON status endpoint on port
# 3000, same pattern as the redis/garage/seaweedfs templates'
# bzync-entrypoint.sh. Typesense's real API port (8108) answers an
# unauthenticated GET / with a 404 "Not Found" (it's not a UI, and / isn't
# a real route), so without this, any browser visit to this project's
# public dashboard URL would show that 404 with no real indication of
# whether Typesense itself is actually up. This gives that same URL a real
# answer instead: a live check against Typesense's own unauthenticated
# /health endpoint, not just a static "ok".
#
# EXPOSE 3000 in the Dockerfile is lower than 8108, so imageExposedPort()
# (compute's startAppContainer) picks 3000 for ingress/health checks
# automatically — the real API is still reachable from other projects on
# the internal network at its real port, 8108, same as before.
set -e

exec /opt/typesense-server --data-dir="$TYPESENSE_DATA_DIR" --api-key="$TYPESENSE_API_KEY" --enable-cors="$TYPESENSE_ENABLE_CORS" &
TYPESENSE_PID=$!

# Same raw /dev/tcp HTTP request this image's own (now-removed, see
# Dockerfile) HEALTHCHECK used — wget/curl aren't in this image, but bash
# is, and bash speaks enough raw HTTP over /dev/tcp for a one-line request.
typesense_reachable() {
  exec 3<>/dev/tcp/127.0.0.1/8108 2>/dev/null || return 1
  printf 'GET /health HTTP/1.0\r\n\r\n' >&3
  head -1 <&3 | grep -q 200
  local result=$?
  exec 3<&-
  return $result
}

serve_status() {
  while true; do
    if typesense_reachable; then
      status_line='HTTP/1.1 200 OK'
      body='{"status":"ok","service":"typesense","typesense":"reachable"}'
    else
      status_line='HTTP/1.1 503 Service Unavailable'
      body='{"status":"error","service":"typesense","typesense":"unreachable"}'
    fi
    printf '%s\r\nContent-Type: application/json\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s' \
      "$status_line" "${#body}" "$body" | nc -l -p 3000 >/dev/null 2>&1 || true
  done
}
serve_status &
STATUS_PID=$!

trap 'kill -TERM "$TYPESENSE_PID" "$STATUS_PID" 2>/dev/null' TERM INT
wait "$TYPESENSE_PID"
