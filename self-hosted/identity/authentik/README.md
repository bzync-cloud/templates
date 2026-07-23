# authentik

A deployable authentik template — clone, push, and Bzync Cloud builds this `Dockerfile` as-is,
same as any other template. authentik is a modern identity provider: SSO, OIDC/OAuth2, SAML,
LDAP outposts, and a flow-based auth engine you can customize per app. There's no managed Bzync
equivalent to fall back on — this deployment **is** your identity provider, and every other app
you protect with it depends on it being up.

**Supported version:** `2026.5.4` (default) — set `AUTHENTIK_VERSION` as a build arg for others
**Default port:** `9000` (HTTP)

## Server + worker, one container

Upstream authentik ships as two roles from the same image — `server` (HTTP/API, what you talk to)
and `worker` (background tasks: emails, sync jobs, flow execution) — normally run as two separate
containers in their own docker-compose. This template is a single container per app, so
`bzync-entrypoint.sh` runs both roles backgrounded in the same container, sharing the same
Postgres. If the worker process dies, the server keeps answering HTTP but background tasks (and
some flows) silently stop — check `docker logs` if things seem to hang rather than error outright.

## Database (required — no SQLite fallback)

authentik has no embedded database. Deploy `data-stores/relational/postgres` from this catalog as
its own app first, then set `AUTHENTIK_POSTGRESQL__HOST` / `__NAME` / `__USER` / `__PASSWORD` in
the dashboard (see `.env.example`) from the values that deployment gives you — there's no
dashboard "link" step on this tier. As of authentik 2025.10 (well before the version this template
pins), Redis is no longer required at all — caching, background tasks, and the embedded outpost
all run on Postgres now, so this is genuinely a two-piece deploy (this app + Postgres), not three.

## Deploying

Push this directory to a repo and connect it in the Bzync Cloud dashboard. Before going live:

1. Deploy Postgres (above) and set the `AUTHENTIK_POSTGRESQL__*` vars.
2. Leave `AUTHENTIK_SECRET_KEY=changeme` as-is — the platform replaces any literal `changeme`
   value with a generated random secret on first deploy. authentik uses this to sign cookies and
   tokens; don't lose it or change it after go-live without expecting every session to invalidate.
3. Leave `AUTHENTIK_BOOTSTRAP_PASSWORD=changeme` as-is too — the first admin account, `akadmin`,
   is created for you automatically from `AUTHENTIK_BOOTSTRAP_EMAIL`/`AUTHENTIK_BOOTSTRAP_PASSWORD`
   on first boot (native to the upstream image, no wrapper script needed here). Find the generated
   password in the dashboard's Variables tab after deploy.
4. Once you have a domain attached, log in as `akadmin` and set it under **System → Brands →
   (your brand) → Domain** — unlike most templates in this repo, the public URL isn't set through
   an env var.

## Run locally

Needs a reachable Postgres on the same Docker network — `.env.example` defaults
`AUTHENTIK_POSTGRESQL__HOST` to `db`, matching a companion container aliased that way:

```bash
docker network create authentik-dev-net
docker run -d --name authentik-dev-db --network authentik-dev-net --network-alias db \
  -e POSTGRES_DB=app -e POSTGRES_USER=app -e POSTGRES_PASSWORD=changeme postgres:16-alpine

docker build -t bzync-authentik-dev .
docker run -d --name authentik-dev --network authentik-dev-net -p 9000:9000 \
  --env-file .env.example bzync-authentik-dev
```

Visit `http://localhost:9000` and log in as `akadmin` with `AUTHENTIK_BOOTSTRAP_PASSWORD`.

## Connecting apps to authentik

Create a **Provider** (OIDC, SAML, proxy, or LDAP outpost) and an **Application** for each app you
want to protect, from the authentik web UI — this isn't an env-var-driven flow the way database
templates in this repo are. Each app you connect then gets its own client ID/secret or SAML
metadata URL from that provider, same as you'd configure against Auth0, Okta, or any other OIDC
provider.

## Backups

Everything except uploaded branding assets and imported TLS keypairs (`/media`, `/certs` — the
two volumes this template persists) lives in Postgres. Back up the Postgres deployment this
points at; losing it loses users, flows, providers, and every application binding, not just this
container's own state.
