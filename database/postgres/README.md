# Postgres — Local Dev Reference

A local Postgres container matching what Bzync Cloud Managed Databases (MDB) provisions in
production, so you can develop against the same engine version before linking the real thing.

**Supported versions:** `16` (default), `15`, `14`
**Default port:** `5432`

## Run locally

```bash
docker build -t bzync-postgres-dev .
docker run -d --name postgres-dev -p 5432:5432 --env-file .env.example bzync-postgres-dev
```

Connect with `psql`:

```bash
psql "postgres://app:changeme@localhost:5432/app"
```

## Using a real managed database

This directory is a local dev stand-in — it isn't deployed by Bzync Cloud. Provision the real
thing from the dashboard: **Databases → Create → Postgres**, then link it to your app's
environment. The platform injects these variables automatically:

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
