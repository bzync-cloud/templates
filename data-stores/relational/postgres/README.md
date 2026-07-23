# Postgres

A deployable Postgres template — clone, push, and Bzync Cloud builds this `Dockerfile` as-is,
same as any other template. It matches the exact engine/version Bzync Cloud's production Managed
Databases (MDB) provisions — but this tier has no managed database service of its own (mdb was
removed here; see the workspace root `README.md`), so it doubles as a local dev container rather
than a stand-in for a real managed instance.

**Supported versions:** `16` (default), `15`, `14`
**Default port:** `5432` — see "Status endpoint" below for why `3000` also matters

## Status endpoint

Postgres speaks its own binary protocol, not HTTP, so visiting this project's public dashboard
URL directly in a browser used to just show Traefik's bare "Bad Gateway" — Postgres was fine,
there was just nothing that could answer an HTTP request. `bzync-entrypoint.sh` now also serves a
small JSON status endpoint on `3000` (a live `pg_isready` against the real `postgres` process, not
a static response):

```bash
curl https://your-app.app.bzync.cloud/
# {"status":"ok","service":"postgres","postgres":"reachable"}
```

`3000` is EXPOSEd alongside `5432` specifically because it's the lower-numbered port — Bzync
Cloud's ingress and health checks target the lowest-numbered `EXPOSE`d port in the image (see
`imageExposedPort()` in compute), so this is what makes the platform route the public URL there
instead of at raw Postgres. This has no effect on how other apps actually connect to Postgres —
they still dial the real protocol port, `5432`, directly over the internal network (see
"Connecting another app to this database" below); `3000` is purely for the public URL / health
checks.

## Deploying

Push this directory to a repo and connect it in the Bzync Cloud dashboard like any other
template — it builds and runs as a single-container service. Set `POSTGRES_DB`,
`POSTGRES_USER`, and `POSTGRES_PASSWORD` in the dashboard for the environment (see
`.env.example`). A deployed instance here is a plain container, not a managed one — no
automatic replication, backups, or HA, and no managed alternative to fall back to on this
tier: this deployment *is* the database for any app here that needs Postgres.

## Run locally

```bash
docker build -t bzync-postgres-dev .
docker run -d --name postgres-dev -p 5432:5432 --env-file .env.example bzync-postgres-dev
```

Connect with `psql`:

```bash
psql "postgres://app:changeme@localhost:5432/app"
```

## Connecting another app to this database

There's no dashboard "link" step on this tier — deploy this template as its own app, then set
matching connection env vars on whichever app needs to reach it (its internal address, plus the
`POSTGRES_DB`/`POSTGRES_USER`/`POSTGRES_PASSWORD` you set above):

```
POSTGRES_HOST
POSTGRES_PORT
POSTGRES_DB
POSTGRES_USER
POSTGRES_PASSWORD
DATABASE_URL   # postgres://user:password@host:port/dbname
```

## Connecting from code

**Node (`pg`):**

```js
import { Client } from "pg";
const client = new Client({ connectionString: process.env.DATABASE_URL });
await client.connect();
```

**Python (`psycopg`):**

```python
import os, psycopg
conn = psycopg.connect(os.environ["DATABASE_URL"])
```

**Go (`pgx`):**

```go
pool, err := pgxpool.New(ctx, os.Getenv("DATABASE_URL"))
```
