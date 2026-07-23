#!/bin/sh
# Wraps the upstream docker-entrypoint.sh with a minimal HTTP status
# endpoint on port 3000. MongoDB speaks its own binary protocol on 27017,
# not HTTP, so visiting this project's public dashboard URL directly in a
# browser used to just show Traefik's bare "Bad Gateway" — MongoDB was
# fine, there was just nothing that could answer an HTTP request. This
# gives that same URL a real answer instead: a live `mongosh` ping against
# the real mongod process, not just a static response.
#
# EXPOSE 3000 in the Dockerfile is lower than 27017, so imageExposedPort()
# (compute's startAppContainer) picks 3000 for ingress/health checks
# automatically — MongoDB itself is still reachable from other projects on
# the internal network at its real port, 27017, same as before.
set -e

docker-entrypoint.sh mongod &
MAIN_PID=$!

serve_status() {
  while true; do
    if mongosh --quiet --eval 'db.adminCommand("ping")' \
        "mongodb://$MONGO_INITDB_ROOT_USERNAME:$MONGO_INITDB_ROOT_PASSWORD@127.0.0.1:27017/admin" \
        >/dev/null 2>&1; then
      status_line='HTTP/1.1 200 OK'
      body='{"status":"ok","service":"mongodb","mongodb":"reachable"}'
    else
      status_line='HTTP/1.1 503 Service Unavailable'
      body='{"status":"error","service":"mongodb","mongodb":"unreachable"}'
    fi
    printf '%s\r\nContent-Type: application/json\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s' \
      "$status_line" "${#body}" "$body" | nc -l -p 3000 >/dev/null 2>&1 || true
  done
}
serve_status &
STATUS_PID=$!

trap 'kill -TERM "$MAIN_PID" "$STATUS_PID" 2>/dev/null' TERM INT
wait "$MAIN_PID"
