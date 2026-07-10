# Odoo Starter

This template runs Odoo with PostgreSQL and a mounted `addons/` directory for custom modules.

## Run locally

```bash
cp .env.example .env
docker compose up --build
```

Open `http://localhost:8069`.

Change `POSTGRES_PASSWORD`, `PASSWORD`, and `admin_passwd` in `config/odoo.conf` before deploying.
