#!/bin/sh
# Wraps garage with a minimal HTTP JSON status endpoint on port 3000, same
# pattern as the redis template's bzync-entrypoint.sh. Garage's S3 API
# speaks HTTP but answers an unauthenticated GET / with a 403 "AccessDenied"
# XML error (it's not a UI), so without this, any browser visit to this
# project's public dashboard URL would show that raw S3 error with no
# indication of whether Garage itself is actually up. This gives that same
# URL a real answer instead: a live check against Garage's own unauthenticated
# admin /health endpoint, not just a static "ok".
#
# EXPOSE 3000 in the Dockerfile is lower than 3900, so imageExposedPort()
# (compute's startAppContainer) picks 3000 for ingress/health checks
# automatically — Garage's S3 API is still reachable from other projects on
# the internal network at its real port, 3900, same as before.
set -e

# Garage requires rpc_secret to be exactly 32 bytes of hex — Bzync Cloud's
# generic "changeme" seed-time secret generator produces a base64url string
# instead, which Garage rejects outright at startup ("expected 32 bytes of
# random hex"). Since this is a single-node deployment with no peers ever
# joining, there's nothing that needs this secret to be stable across
# restarts, so it's generated fresh here on every start instead of being a
# configurable (and startup-breaking) env var. rpc_secret_file also requires
# mode 0600 (Garage refuses a world-readable secret file).
head -c32 /dev/urandom | od -An -tx1 | tr -d ' \n' > /etc/garage-rpc-secret
chmod 600 /etc/garage-rpc-secret

# Garage's default S3 secret key must be at least 16 characters — the
# platform's literal "changeme" seed placeholder (8 chars) fails this at
# boot ("Secret keys should be at least 16 characters long"), even though
# that same placeholder satisfies the *access* key's own separate 8-char
# minimum. Unlike rpc_secret above, this can't be randomized on every
# start: other apps are told to copy this value in (see README), so it has
# to stay stable across restarts. Only the still-unsubstituted literal
# placeholder gets padded — once the platform's seed-time secret generator
# replaces "changeme" with a real value in production, this is a no-op.
if [ "$GARAGE_DEFAULT_SECRET_KEY" = "changeme" ]; then
  export GARAGE_DEFAULT_SECRET_KEY="changemechangeme"
fi

/garage server --single-node --default-bucket &
GARAGE_PID=$!

serve_status() {
  while true; do
    if wget -qO- http://127.0.0.1:3903/health 2>/dev/null | grep -q "fully operational"; then
      status_line='HTTP/1.1 200 OK'
      body='{"status":"ok","service":"garage","garage":"reachable"}'
    else
      status_line='HTTP/1.1 503 Service Unavailable'
      body='{"status":"error","service":"garage","garage":"unreachable"}'
    fi
    printf '%s\r\nContent-Type: application/json\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s' \
      "$status_line" "${#body}" "$body" | nc -l -p 3000 >/dev/null 2>&1 || true
  done
}
serve_status &
STATUS_PID=$!

trap 'kill -TERM "$GARAGE_PID" "$STATUS_PID" 2>/dev/null' TERM INT
wait "$GARAGE_PID"
