# n8n

A production-shaped, self-hosted n8n instance (workflow automation) — clone, push, and Bzync
Cloud builds this `Dockerfile` as-is, same as any other template. Unlike `data-stores/*`, there's
no managed Bzync equivalent to fall back on: this deployment **is** your n8n instance, and its
`/home/node/.n8n` volume holds real, non-reproducible data (credentials, workflow definitions when
running on SQLite, and the encryption key's local state).

**Default port:** `5678`

## Deploying

Push this directory to a repo and connect it in the Bzync Cloud dashboard. Before going live:

1. Set `WEBHOOK_URL` to your real domain (see `.env.example`) — n8n uses this to build webhook and
   OAuth callback URLs.
2. Leave `N8N_ENCRYPTION_KEY=changeme` as-is — the platform replaces any literal `changeme` value
   with a generated random secret on first deploy. Back this value up once it's real: losing it
   makes every stored credential unreadable.
3. The first owner account is created for you automatically from `N8N_ADMIN_*` — see
   `.env.example`.

### Deploy strategy: Standard vs. Blue-Green/Rolling

Set this project's deploy strategy under Project → Settings → Deploy Strategy.

**Standard** works out of the box with no extra configuration — it always destroys the old
container before starting the new one, so only one n8n instance ever touches
`/home/node/.n8n` at a time.

**Blue-Green and Rolling** briefly run the new instance alongside the old one against the *same*
`/home/node/.n8n` volume — that overlap is the entire point of both strategies (zero-downtime
cutover). The risk here is the default database itself: SQLite only allows one writer at a time, so
a real write landing on both instances in the same instant (rare, given the overlap window is
seconds) can produce a "database is locked" error, and n8n's own task/queue bookkeeping isn't
designed to run from two processes against one SQLite file. For that risk to go away entirely, link
a Postgres database instead (see "SQLite vs. Postgres" below) — n8n supports concurrent instances
against a shared Postgres database natively. Until then, stick to Standard.

## Run locally

```bash
docker build -t bzync-n8n-dev .
docker run -d --name n8n-dev -p 5678:5678 --env-file .env.example bzync-n8n-dev
```

Visit `http://localhost:5678` — the first owner account is created automatically from the
`N8N_ADMIN_*` values in `.env.example`.

## SQLite vs. Postgres

The default needs no separate database — the whole instance's state (credentials, workflows,
executions) lives in `/home/node/.n8n` (SQLite). Fine for solo or small-team use. For heavier or
multi-instance use, link a `data-stores/relational/postgres` deployment from this catalog in the
Bzync Cloud dashboard — the platform injects `DATABASE_HOST`/`DATABASE_PORT`/`DATABASE_NAME`/
`DATABASE_USER`/`DATABASE_PASSWORD`, and `start.sh` translates these to n8n's native
`DB_POSTGRESDB_*` vars automatically (see `.env.example`'s `DB_POSTGRESDB_SCHEMA`). n8n migrates
the schema automatically on next boot against the new database — it does **not** migrate your
existing SQLite workflows/credentials across; use `n8n export:workflow --all` and
`n8n export:credentials --all` before switching, then import them again after.
