# Odoo Starter

This template runs Odoo with PostgreSQL and a mounted `addons/` directory for custom modules.

## Run locally

```bash
cp .env.development.example .env.development
docker compose -f docker-compose.development.yml up
```

Open `http://localhost:8069`.

## Production-style run

```bash
cp .env.example .env
docker compose up --build
```

Change `POSTGRES_PASSWORD`, `PASSWORD`, and `admin_passwd` in `config/odoo.conf` before deploying.
