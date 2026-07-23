# Valkey

A deployable Valkey template — clone, push, and Bzync Cloud builds this `Dockerfile` as-is, same
as any other template. Valkey is a Redis-protocol-compatible fork (the project Redis's own
maintainers forked to under the Linux Foundation), so it's a drop-in alternative to the `redis`
template in this same `cache` category — same protocol, same client libraries, same commands.
This tier has no managed database service of its own (mdb was removed here; see the workspace
root `README.md`), so this doubles as a local dev container rather than a stand-in for a real
managed instance.

**Supported versions:** `8` (default, `8.0-alpine`), `7` (`7.2-alpine`)
**Default port:** `6379` (Redis-compatible protocol) — see "Status endpoint" below for why `3000`
also matters

## Status endpoint

Valkey speaks the Redis wire protocol, not HTTP, so visiting this project's public dashboard URL
directly in a browser used to just show Traefik's bare "Bad Gateway" — Valkey was fine, there was
just nothing that could answer an HTTP request. `bzync-entrypoint.sh` now also serves a small JSON
status endpoint on `3000` (a live `valkey-cli ping` against the real `valkey-server` process, not
a static response):

```bash
curl https://your-app.app.bzync.cloud/
# {"status":"ok","service":"valkey","valkey":"reachable"}
```

`3000` is EXPOSEd alongside `6379` specifically because it's the lower-numbered port — Bzync
Cloud's ingress and health checks target the lowest-numbered `EXPOSE`d port in the image (see
`imageExposedPort()` in compute), so this is what makes the platform route the public URL there
instead of at raw Valkey. This has no effect on how other apps actually connect to Valkey — they
still dial the real protocol port, `6379`, directly over the internal network (see "Connecting
another app to this database" below); `3000` is purely for the public URL / health checks.

## Deploying

Push this directory to a repo and connect it in the Bzync Cloud dashboard like any other
template — it builds and runs as a single-container service. Set `VALKEY_PASSWORD` in the
dashboard for the environment (see `.env.example`). A deployed instance here is a plain
container, not a managed one — no automatic replication, backups, or HA, its `appendonly`
persistence lives on the container's ephemeral disk unless you attach a volume, and there's no
managed alternative to fall back to on this tier: this deployment *is* the database for any app
here that needs Valkey.

## Run locally

```bash
docker build -t bzync-valkey-dev .
docker run -d --name valkey-dev -p 6379:6379 --env-file .env.example bzync-valkey-dev
```

Connect with `valkey-cli` (or `redis-cli` — either works, same protocol):

```bash
valkey-cli -a changeme --no-auth-warning -h 127.0.0.1 -p 6379 ping
```

## Connecting another app to this database

There's no dashboard "link" step on this tier — deploy this template as its own app, then set
matching connection env vars on whichever app needs to reach it (its internal address, plus the
`VALKEY_PASSWORD` you set above):

```
DB_HOST
DB_PORT
DB_PASSWORD
DATABASE_URL   # redis://:password@host:port
```

## Connecting from code

Any Redis client library works against Valkey unchanged — connect it exactly as you would to
Redis.

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
