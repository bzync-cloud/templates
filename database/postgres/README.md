# Postgres

A deployable Postgres template — clone, push, and Bzync Cloud builds this `Dockerfile` as-is,
same as any other template. It matches the exact engine/version Bzync Cloud's production Managed
Databases (MDB) provisions — but this tier has no managed database service of its own (mdb was
removed here; see the workspace root `README.md`), so it doubles as a local dev container rather
than a stand-in for a real managed instance.

**Supported versions:** `16` (default), `15`, `14`
**Default port:** `5432`

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
