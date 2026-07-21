#!/bin/sh
set -e

# focalboard-server only reads config.json (or -dbtype/-dbconfig CLI flags
# for the database) — it has no env-var config overrides of its own. Patch
# the image's baked config.json in place before handing off, so the usual
# Bzync Cloud dashboard env vars still work as expected.
CONFIG=/opt/focalboard/config.json

if [ -n "$FOCALBOARD_SERVERROOT" ]; then
  sed -i "s#\"serverRoot\": \".*\"#\"serverRoot\": \"$FOCALBOARD_SERVERROOT\"#" "$CONFIG"
fi

# When a managed database is linked in the Bzync Cloud dashboard, the
# platform injects DB_HOST, DB_PORT, DB_NAME, DB_USER, and DB_PASSWORD.
# Translate these into focalboard's Postgres connection string — no manual
# configuration needed. Without a linked database, the baked-in SQLite
# default (./data/focalboard.db) applies.
if [ -n "$DB_HOST" ]; then
  dbconfig="postgres://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT:-5432}/${DB_NAME}?sslmode=disable"
  sed -i "s#\"dbtype\": \".*\"#\"dbtype\": \"postgres\"#" "$CONFIG"
  sed -i "s#\"dbconfig\": \".*\"#\"dbconfig\": \"$dbconfig\"#" "$CONFIG"
fi

exec /opt/focalboard/bin/focalboard-server
