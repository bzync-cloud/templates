# Plane

A self-hosted Plane instance, using the official `plane-aio-community` ("all-in-one") image that
bundles the API, web app, background worker, scheduler, realtime server, and an internal nginx
proxy into a single container — clone, push, and Bzync Cloud builds this `Dockerfile` as-is, same
as any other template.

**Heads up:** unlike every other template in this catalog, this one needs **four external
services** just to start — it has no embedded database, cache, queue, or file storage of its own.
If you just want a lighter-weight project tracker with fewer moving parts, see
`project-management/vikunja`, `project-management/focalboard`, or `project-management/leantime`
instead.

**Supported versions:** `stable` (default) — set `PLANE_VERSION` as a build arg for others (e.g.
a pinned `vX.Y.Z`)
**Default port:** `80`

## What you need before deploying

| Service | Env vars | Where it can come from |
|---|---|---|
| PostgreSQL | `DATABASE_URL` | `database/postgres` from this catalog, deployed as its own app |
| Redis | `REDIS_URL` | `database/redis` from this catalog, deployed as its own app |
| AMQP broker (RabbitMQ) | `AMQP_URL` | No Bzync template for this — self-host RabbitMQ (e.g. the official `rabbitmq` image as its own Bzync Cloud deployment) or use a managed provider |
| S3-compatible object storage | `AWS_*` | No Bzync template for this — a real AWS S3 bucket, Cloudflare R2, Backblaze B2, or a self-hosted MinIO deployment |

There's no dashboard "link" step on this tier: deploy `database/postgres` and `database/redis`
as their own apps, then fold their connection details into `DATABASE_URL` / `REDIS_URL` by hand
(Plane wants full connection URLs, not individual host/port/user fields). RabbitMQ and object
storage are entirely on you to provision and wire up — this template doesn't set them up for
you.

## Deploying

1. Deploy `database/postgres` and `database/redis` from this catalog as their own apps, and
   stand up (or otherwise obtain) a RabbitMQ instance and an S3-compatible bucket.
2. Set every variable in `.env.example` to match, especially `DOMAIN_NAME` (bare hostname, no
   scheme or port — e.g. `plane.your-domain.example.com`) and `SECRET_KEY` (leave as `change-me`
   only for local testing; set a real random value for anything reachable outside your own
   machine — this template doesn't get the platform's automatic `changeme`-replacement treatment
   since it isn't the literal string `changeme`).
3. Push and connect the repo in the Bzync Cloud dashboard.

There's no persistent volume to worry about — all of Plane's state (workspaces, issues,
attachments) lives in the Postgres database and the S3 bucket, not in the container itself.

## Run locally

Bring up all four dependencies alongside it:

```bash
docker network create plane-dev

docker run -d --name db --network plane-dev \
  -e POSTGRES_USER=plane -e POSTGRES_PASSWORD=change-me -e POSTGRES_DB=plane \
  postgres:16-alpine

docker run -d --name redis --network plane-dev redis:7-alpine

docker run -d --name rabbitmq --network plane-dev \
  -e RABBITMQ_DEFAULT_USER=plane -e RABBITMQ_DEFAULT_PASS=change-me \
  rabbitmq:3-management-alpine

docker run -d --name minio --network plane-dev \
  -e MINIO_ROOT_USER=change-me -e MINIO_ROOT_PASSWORD=change-me-too \
  minio/minio server /data
# Create the bucket Plane will write to:
docker exec minio mc alias set local http://localhost:9000 change-me change-me-too
docker exec minio mc mb local/plane

docker build -t bzync-plane-dev .
docker run -d --name plane-dev --network plane-dev -p 8080:80 \
  -e DOMAIN_NAME=localhost -e APP_PROTOCOL=http -e SECRET_KEY=change-me \
  -e DATABASE_URL=postgres://plane:change-me@db:5432/plane \
  -e REDIS_URL=redis://redis:6379/ \
  -e AMQP_URL=amqp://plane:change-me@rabbitmq:5672/ \
  -e AWS_REGION=us-east-1 -e AWS_ACCESS_KEY_ID=change-me -e AWS_SECRET_ACCESS_KEY=change-me-too \
  -e AWS_S3_BUCKET_NAME=plane -e AWS_S3_ENDPOINT_URL=http://minio:9000 \
  bzync-plane-dev
```

Visit `http://localhost:8080` — first boot runs database migrations and takes noticeably longer
than the other templates here (closer to a minute than a few seconds) before it starts
responding.
