# Redis

A deployable Redis template — clone, push, and Bzync Cloud builds this `Dockerfile` as-is, same
as any other template. It also matches the exact engine/version Bzync Cloud Managed Databases
(MDB) provisions in production, so it doubles as a local dev container.

**Supported versions:** `7` (default, `7.2-alpine`), `6` (`6.2-alpine`)
**Default port:** `6379`

## Deploying

Push this directory to a repo and connect it in the Bzync Cloud dashboard like any other
template — it builds and runs as a single-container service. Set `REDIS_PASSWORD` in the
dashboard for the environment (see `.env.example`). A deployed instance here is a plain
container, not a managed one — no automatic replication, backups, or HA, and its `appendonly`
persistence lives on the container's ephemeral disk unless you attach a volume. For production
data, provision through **Databases → Create → Redis** (MDB) instead and link it to your app's
environment.

## Run locally

```bash
docker build -t bzync-redis-dev .
docker run -d --name redis-dev -p 6379:6379 --env-file .env.example bzync-redis-dev
```

Connect with `redis-cli`:

```bash
redis-cli -a changeme --no-auth-warning -h 127.0.0.1 -p 6379 ping
```

## Using MDB instead

If you provision a real managed Redis from **Databases → Create → Redis** and link it to your
app's environment, the platform injects these variables automatically:

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
