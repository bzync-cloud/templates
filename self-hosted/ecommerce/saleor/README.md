# Saleor

A deployable Saleor template — clone, push, and Bzync Cloud builds this `Dockerfile` as-is, same
as any other template. Saleor is a headless, API-only (GraphQL) commerce platform — there's no
built-in storefront UI here, just the backend/API and its admin Dashboard app. Pair it with a
separate storefront frontend (Saleor's own React storefront, or any custom one) deployed as its
own app. There's no managed Bzync equivalent to fall back on — this deployment **is** your
commerce backend.

**Supported version:** `latest` (default) — set `SALEOR_VERSION` as a build arg to pin one
**Default port:** `8000` (GraphQL API at `/graphql/`)

## Why this template runs three processes in one container

Saleor's own reference deployment (`saleor-platform`) runs the API server and a Celery worker as
two separate containers, with database migrations run as a separate one-off step before either
starts. This template is a single container per app, so `bzync-entrypoint.sh` wraps all of that:
runs `manage.py migrate` once on boot (**first boot runs a very long migration chain — years of
Saleor schema history — expect several minutes before the API answers**, similar to GitLab CE or
Keycloak elsewhere in this repo), then starts the Celery worker (bundled with `-B`, so the beat
scheduler doesn't need a fourth process) and the `uvicorn` API server backgrounded together. If
the worker process dies, the API keeps answering GraphQL queries but async work (webhooks, order
event processing, search indexing) stops silently — check `docker logs` if things seem to hang.

## Database + broker (both required — no embedded fallback)

Saleor needs both Postgres and Redis. Deploy `data-stores/relational/postgres` and
`data-stores/cache/redis` (or `valkey`/`keydb`, same protocol) from this catalog as their own apps
first, then set `DATABASE_URL` / `REDIS_URL` / `CELERY_BROKER_URL` in the dashboard (see
`.env.example`) from the values those deployments give you — there's no dashboard "link" step on
this tier.

## Deploying

Push this directory to a repo and connect it in the Bzync Cloud dashboard. Before going live:

1. Deploy Postgres and Redis (above) and set the connection vars.
2. Leave `SECRET_KEY=changeme` as-is — the platform replaces any literal `changeme` value with a
   generated random secret on first deploy.
3. Leave `DJANGO_SUPERUSER_PASSWORD=changeme` as-is too — the first admin account is created for
   you automatically from `DJANGO_SUPERUSER_EMAIL`/`DJANGO_SUPERUSER_PASSWORD` on first boot
   (native Django `createsuperuser --noinput` behavior, no Saleor-specific wrapper needed). Find
   the generated password in the dashboard's Variables tab after deploy, then change it from the
   Dashboard app once logged in.
4. Once you have a domain, set `ALLOWED_HOSTS` to it instead of the wildcard default.

## Run locally

Needs reachable Postgres and Redis on the same Docker network — `.env.example` defaults
`DATABASE_URL`/`REDIS_URL`/`CELERY_BROKER_URL` to `db`/`redis`, matching companion containers
aliased that way:

```bash
docker network create saleor-dev-net
docker run -d --name saleor-dev-db --network saleor-dev-net --network-alias db \
  -e POSTGRES_DB=app -e POSTGRES_USER=app -e POSTGRES_PASSWORD=changeme postgres:16-alpine
docker run -d --name saleor-dev-redis --network saleor-dev-net --network-alias redis redis:7-alpine

docker build -t bzync-saleor-dev .
docker run -d --name saleor-dev --network saleor-dev-net -p 8000:8000 \
  --env-file .env.example bzync-saleor-dev
```

Query `http://localhost:8000/graphql/` (a GraphQL client, not a browser page — there's no
storefront UI to visit) once migrations finish.

## Media storage

Uploaded product images and other media live under `/app/media` (the volume this template
persists) by default, on this single container's own disk. For a real deployment, consider
pointing Saleor at `data-stores/object-storage/minio` (also in this catalog) instead via Saleor's
S3-compatible storage settings — local disk storage doesn't survive a redeploy that replaces the
container, only the mounted volume does, and doesn't scale if you ever run more than one instance.

## Backups

Products, orders, customers, and configuration all live in Postgres — back that up. Uploaded
media lives under `/app/media` (or your object storage, if configured) — back that up separately.
Losing either loses real, non-reproducible data.
