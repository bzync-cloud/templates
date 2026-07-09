#!/bin/sh
set -e

# When a managed database is linked in the Bzync Cloud dashboard, the platform
# injects DATABASE_HOST, DATABASE_PORT, DATABASE_NAME, DATABASE_USER, and
# DATABASE_PASSWORD. Translate these to n8n's native env var format so n8n
# automatically uses the linked database without any manual configuration.
if [ -n "$DATABASE_HOST" ]; then
  export DB_TYPE=postgresdb
  export DB_POSTGRESDB_HOST="$DATABASE_HOST"
  export DB_POSTGRESDB_PORT="${DATABASE_PORT:-5432}"
  export DB_POSTGRESDB_DATABASE="${DATABASE_NAME:-n8n}"
  export DB_POSTGRESDB_USER="${DATABASE_USER}"
  export DB_POSTGRESDB_PASSWORD="${DATABASE_PASSWORD}"
fi

exec n8n start
