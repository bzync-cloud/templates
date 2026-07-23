#!/bin/sh
# Polls until app.ini exists and the gitea CLI (Forgejo kept it) can
# actually talk to the (possibly still-migrating) database, then creates
# the first admin user once. Safe to run on every boot: `gitea admin user
# create` fails harmlessly if the username already exists, and we stop
# retrying either way after that.
set -e

CONFIG=/data/gitea/conf/app.ini
LOG=/tmp/bzync-admin-setup.log

for i in $(seq 1 60); do
  [ -f "$CONFIG" ] && break
  sleep 1
done

for i in $(seq 1 60); do
  if su git -c "gitea admin user create --username '$FORGEJO_ADMIN_USERNAME' --password '$FORGEJO_ADMIN_PASSWORD' --email '${FORGEJO_ADMIN_EMAIL:-admin@example.com}' --admin --config $CONFIG" >"$LOG" 2>&1; then
    exit 0
  fi
  grep -qi "already exists" "$LOG" && exit 0
  sleep 2
done

cat "$LOG" >&2
