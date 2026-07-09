# Redis — Local Dev Reference

A local Redis container matching what Bzync Cloud Managed Databases (MDB) provisions in
production, so you can develop against the same engine version before linking the real thing.

**Supported versions:** `7` (default, `7.2-alpine`), `6` (`6.2-alpine`)
**Default port:** `6379`

## Run locally

```bash
docker build -t bzync-redis-dev .
docker run -d --name redis-dev -p 6379:6379 --env-file .env.example bzync-redis-dev
```

Connect with `redis-cli`:

```bash
redis-cli -a changeme --no-auth-warning -h 127.0.0.1 -p 6379 ping
```

## Using a real managed database

This directory is a local dev stand-in — it isn't deployed by Bzync Cloud. Provision the real
thing from the dashboard: **Databases → Create → Redis**, then link it to your app's
environment. The platform injects these variables automatically:

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
