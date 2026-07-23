#!/bin/sh
# Wraps `weed mini` with a minimal HTTP JSON status endpoint on port 3000,
# same pattern as the redis and garage templates' bzync-entrypoint.sh.
# SeaweedFS's S3 API speaks HTTP but answers an unauthenticated GET / with a
# 403-style error (it's not a UI), so without this, any browser visit to
# this project's public dashboard URL would show that raw error with no
# indication of whether SeaweedFS itself is actually up. This gives that
# same URL a real answer instead: a live check against the master's own
# /cluster/status endpoint, not just a static "ok".
#
# EXPOSE 3000 in the Dockerfile is lower than 8333, so imageExposedPort()
# (compute's startAppContainer) picks 3000 for ingress/health checks
# automatically — the S3 API is still reachable from other projects on the
# internal network at its real port, 8333, same as before.
set -e

# Runs as root, before the base image's own /entrypoint.sh drops privileges
# to the `seaweed` user (see its chown-then-su-exec logic) — writes the S3
# identity config here so the seaweed user can still read it afterwards.
# `weed mini` has no direct env-var equivalent for setting S3 credentials
# (confirmed broken upstream for AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY),
# so the -s3.config flag pointing at this generated file is the only
# reliable way to set a fixed access/secret key pair.
mkdir -p /etc/seaweedfs
cat > /etc/seaweedfs/s3.json <<JSON
{
  "identities": [
    {
      "name": "admin",
      "credentials": [
        {
          "accessKey": "${WEED_S3_ACCESS_KEY}",
          "secretKey": "${WEED_S3_SECRET_KEY}"
        }
      ],
      "actions": ["Admin", "Read", "Write", "List", "Tagging"]
    }
  ]
}
JSON
chmod 644 /etc/seaweedfs/s3.json

# Not exec'd (unlike a plain pass-through wrapper) so this script keeps
# running to also serve the status endpoint below — same structure as the
# redis template. /entrypoint.sh's own root-drop re-execs itself in place
# (exec su-exec seaweed "$0" "$@", then exec weed mini ...), so the PID
# captured here with $! stays valid to signal all the way down that chain.
/entrypoint.sh "$@" &
WEED_PID=$!

serve_status() {
  while true; do
    if wget -qO- http://127.0.0.1:9333/cluster/status 2>/dev/null | grep -q '"IsLeader"'; then
      status_line='HTTP/1.1 200 OK'
      body='{"status":"ok","service":"seaweedfs","seaweedfs":"reachable"}'
    else
      status_line='HTTP/1.1 503 Service Unavailable'
      body='{"status":"error","service":"seaweedfs","seaweedfs":"unreachable"}'
    fi
    printf '%s\r\nContent-Type: application/json\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s' \
      "$status_line" "${#body}" "$body" | nc -l -p 3000 >/dev/null 2>&1 || true
  done
}
serve_status &
STATUS_PID=$!

trap 'kill -TERM "$WEED_PID" "$STATUS_PID" 2>/dev/null' TERM INT
wait "$WEED_PID"
