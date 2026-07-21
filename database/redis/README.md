# Redis

A deployable Redis template — clone, push, and Bzync Cloud builds this `Dockerfile` as-is, same
as any other template. It matches the exact engine/version Bzync Cloud's production Managed
Databases (MDB) provisions — but this tier has no managed database service of its own (mdb was
removed here; see the workspace root `README.md`), so it doubles as a local dev container rather
than a stand-in for a real managed instance.

**Supported versions:** `7` (default, `7.2-alpine`), `6` (`6.2-alpine`)
**Default port:** `6379`

## Deploying

Push this directory to a repo and connect it in the Bzync Cloud dashboard like any other
template — it builds and runs as a single-container service. Set `REDIS_PASSWORD` in the
dashboard for the environment (see `.env.example`). A deployed instance here is a plain
container, not a managed one — no automatic replication, backups, or HA, its `appendonly`
persistence lives on the container's ephemeral disk unless you attach a volume, and there's no
managed alternative to fall back to on this tier: this deployment *is* the database for any app
here that needs Redis.

## Run locally

```bash
docker build -t bzync-redis-dev .
docker run -d --name redis-dev -p 6379:6379 --env-file .env.example bzync-redis-dev
```

Connect with `redis-cli`:

```bash
redis-cli -a changeme --no-auth-warning -h 127.0.0.1 -p 6379 ping
```

## Connecting another app to this database

There's no dashboard "link" step on this tier — deploy this template as its own app, then set
matching connection env vars on whichever app needs to reach it (its internal address, plus the
`REDIS_PASSWORD` you set above):

```
DB_HOST
DB_PORT
DB_PASSWORD
DATABASE_URL   # redis://:password@host:port
```

## Connecting from code

**Node (`ioredis`):**

```js
import Redis from "ioredis";
const redis = new Redis(process.env.DATABASE_URL);
```

**Python (`redis-py`):**

```python
import os, redis
r = redis.from_url(os.environ["DATABASE_URL"])
```

**Go (`go-redis`):**

```go
opt, err := redis.ParseURL(os.Getenv("DATABASE_URL"))
rdb := redis.NewClient(opt)
```
