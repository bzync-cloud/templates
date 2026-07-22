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

# n8n only accepts N8N_INSTANCE_OWNER_PASSWORD_HASH pre-hashed (a plaintext
# value there breaks login) — hash it here so N8N_ADMIN_PASSWORD in
# .env.example can stay a plain, platform-generated secret like every
# other credential in this catalog.
if [ -n "$N8N_ADMIN_EMAIL" ] && [ -n "$N8N_ADMIN_PASSWORD" ]; then
  export N8N_INSTANCE_OWNER_MANAGED_BY_ENV=true
  export N8N_INSTANCE_OWNER_EMAIL="$N8N_ADMIN_EMAIL"
  export N8N_INSTANCE_OWNER_FIRST_NAME="${N8N_ADMIN_FIRST_NAME:-Admin}"
  export N8N_INSTANCE_OWNER_LAST_NAME="${N8N_ADMIN_LAST_NAME:-User}"
  export N8N_INSTANCE_OWNER_PASSWORD_HASH="$(node -e "console.log(require('bcryptjs').hashSync(process.env.N8N_ADMIN_PASSWORD, 10))")"
fi

exec n8n start
