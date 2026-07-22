#!/bin/sh
# Gogs has no GITEA__-style env-to-config system (it predates that feature
# in its own upstream fork, Gitea), so there's no way to configure it
# entirely through environment variables the way gitea/forgejo/gitlab-ce in
# this repo do. This renders app.ini from env vars via the template below,
# standing in for the interactive install wizard (INSTALL_LOCK is baked
# into the template so that wizard never runs).
#
# Only renders once: after the first boot, admin-UI changes and the secret
# values Gogs itself may rewrite into app.ini live in this same file, so
# re-rendering on every restart would silently discard them.
#
# Gogs' default config path (/app/gogs/custom/conf/app.ini) lives outside
# /data, so a symlink puts the persisted file where Gogs actually looks for
# it — this must be relinked on every boot since /app/gogs/custom isn't
# part of the persistent volume.
set -e

mkdir -p /data/gogs/conf

if [ ! -f /data/gogs/conf/app.ini ]; then
  envsubst < /etc/gogs/app.ini.template > /data/gogs/conf/app.ini
fi

mkdir -p /app/gogs/custom
ln -sfn /data/gogs/conf /app/gogs/custom/conf

# Backgrounded (rather than exec'd) so bzync-create-admin.sh can run
# alongside it — the trap forwards docker stop's SIGTERM through to Gogs
# for a clean shutdown instead of waiting out the full kill timeout.
/app/gogs/docker/start.sh &
MAIN_PID=$!
trap 'kill -TERM "$MAIN_PID" 2>/dev/null' TERM INT

if [ -n "$GOGS_ADMIN_USERNAME" ] && [ -n "$GOGS_ADMIN_PASSWORD" ]; then
  /usr/local/bin/bzync-create-admin.sh &
fi

wait "$MAIN_PID"
