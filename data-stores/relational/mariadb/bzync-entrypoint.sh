#!/bin/sh
# Wraps the upstream docker-entrypoint.sh with a minimal HTTP status
# endpoint on port 3000. MariaDB speaks its own binary protocol on 3306,
# not HTTP, so visiting this project's public dashboard URL directly in a
# browser used to just show Traefik's bare "Bad Gateway" — MariaDB was
# fine, there was just nothing that could answer an HTTP request. This
# gives that same URL a real answer instead: a live `mariadb-admin ping`
# against the real mariadbd process, not just a static response.
#
# EXPOSE 3000 in the Dockerfile is lower than 3306, so imageExposedPort()
# (compute's startAppContainer) picks 3000 for ingress/health checks
# automatically — MariaDB itself is still reachable from other projects on
# the internal network at its real port, 3306, same as before.
set -e

docker-entrypoint.sh mariadbd &
MAIN_PID=$!

serve_status() {
  while true; do
    if mariadb-admin ping -h 127.0.0.1 -u"$MARIADB_USER" -p"$MARIADB_PASSWORD" --silent >/dev/null 2>&1; then
      status_line='HTTP/1.1 200 OK'
      body='{"status":"ok","service":"mariadb","mariadb":"reachable"}'
    else
      status_line='HTTP/1.1 503 Service Unavailable'
      body='{"status":"error","service":"mariadb","mariadb":"unreachable"}'
    fi
    printf '%s\r\nContent-Type: application/json\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s' \
      "$status_line" "${#body}" "$body" | nc -l -p 3000 >/dev/null 2>&1 || true
  done
}
serve_status &
STATUS_PID=$!

trap 'kill -TERM "$MAIN_PID" "$STATUS_PID" 2>/dev/null' TERM INT
wait "$MAIN_PID"
