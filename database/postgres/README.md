# Postgres

A deployable Postgres template — clone, push, and Bzync Cloud builds this `Dockerfile` as-is,
same as any other template. It also matches the exact engine/version Bzync Cloud Managed
Databases (MDB) provisions in production, so it doubles as a local dev container.

**Supported versions:** `16` (default), `15`, `14`
**Default port:** `5432`

## Deploying

Push this directory to a repo and connect it in the Bzync Cloud dashboard like any other
template — it builds and runs as a single-container service. Set `POSTGRES_DB`,
`POSTGRES_USER`, and `POSTGRES_PASSWORD` in the dashboard for the environment (see
`.env.example`). A deployed instance here is a plain container, not a managed one — no
automatic replication, backups, or HA. For production data, provision through
**Databases → Create → Postgres** (MDB) instead and link it to your app's environment.

## Run locally

```bash
docker build -t bzync-postgres-dev .
docker run -d --name postgres-dev -p 5432:5432 --env-file .env.example bzync-postgres-dev
```

Connect with `psql`:

```bash
psql "postgres://app:changeme@localhost:5432/app"
```

## Using MDB instead

If you provision a real managed Postgres from **Databases → Create → Postgres** and link it to
your app's environment, the platform injects these variables automatically:

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
