#!/bin/sh
# Polls until app.ini exists and Gogs' own sqlite migration (run by
# start.sh on first boot) has finished, then creates the first admin user
# once. Safe to run on every boot: `gogs admin create-user` fails
# harmlessly if the username already exists, and we stop retrying either
# way after that.
set -e

CONFIG=/data/gogs/conf/app.ini
LOG=/tmp/bzync-admin-setup.log

# "admin" is a reserved username in Gogs (see README) — refuse to loop
# forever retrying a create that can never succeed.
if [ "$GOGS_ADMIN_USERNAME" = "admin" ]; then
  echo "GOGS_ADMIN_USERNAME cannot be 'admin' (reserved by Gogs) — skipping auto-create" >&2
  exit 1
fi

for i in $(seq 1 60); do
  [ -f "$CONFIG" ] && break
  sleep 1
done

for i in $(seq 1 60); do
  if su git -c "/app/gogs/gogs admin create-user --name '$GOGS_ADMIN_USERNAME' --password '$GOGS_ADMIN_PASSWORD' --email '${GOGS_ADMIN_EMAIL:-admin@example.com}' --admin --config $CONFIG" >"$LOG" 2>&1; then
    exit 0
  fi
  grep -qi "already exist" "$LOG" && exit 0
  sleep 2
done

cat "$LOG" >&2
