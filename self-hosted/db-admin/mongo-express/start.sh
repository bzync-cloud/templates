#!/bin/bash
set -eo pipefail

# When a managed database is linked in the Bzync Cloud dashboard, the platform
# injects DB_HOST, DB_PORT, DB_NAME, DB_USER, and DB_PASSWORD. Translate these
# to mongo-express's native env var names so it automatically connects to the
# linked database without any manual configuration. Without this, the
# upstream entrypoint's own wait-for-mongo loop (see /docker-entrypoint.sh)
# times out against its "mongo" hostname default and the app then crashes on
# its first real connection attempt instead of serving the login page.
if [ -n "$DB_HOST" ]; then
  export ME_CONFIG_MONGODB_SERVER="$DB_HOST"
  export ME_CONFIG_MONGODB_PORT="${DB_PORT:-27017}"
  export ME_CONFIG_MONGODB_AUTH_DATABASE="${DB_NAME:-admin}"
  export ME_CONFIG_MONGODB_AUTH_USERNAME="$DB_USER"
  export ME_CONFIG_MONGODB_AUTH_PASSWORD="$DB_PASSWORD"
  # app.js ignores ME_CONFIG_MONGODB_URL once _SERVER is set, but
  # docker-entrypoint.sh's own wait-for-mongo loop only ever reads URL —
  # keep it pointed at the real host too, or that loop wastes ~10s waiting
  # on the image's baked-in "mongo" default before falling through anyway.
  export ME_CONFIG_MONGODB_URL="mongodb://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT:-27017}/${DB_NAME:-admin}?authSource=admin"
fi

exec /docker-entrypoint.sh "$@"
