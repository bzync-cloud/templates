# Keycloak

A deployable Keycloak template — clone, push, and Bzync Cloud builds this `Dockerfile` as-is,
same as any other template. Keycloak is the enterprise-standard open-source identity provider:
SSO, OIDC/OAuth2, SAML, fine-grained RBAC, and a mature admin console, backed by Red Hat. There's
no managed Bzync equivalent to fall back on — this deployment **is** your identity provider, and
every other app you protect with it depends on it being up.

**Supported version:** `26.7` (default) — set `KEYCLOAK_VERSION` as a build arg for others
**Default port:** `8080` (HTTP) — `9000` also matters, see "Health checks" below

## Before you deploy this: first boot is slow

Keycloak runs a long chain of Liquibase schema migrations against Postgres on first boot —
observed **up to 6 minutes** before the admin console answers, even though the JVM itself starts
in seconds. `HEALTHCHECK` in `Dockerfile` uses a 60s `start-period` with 5 retries at 30s
intervals (5.5 minutes total grace) to match; if a deploy looks stuck at "starting" in the
dashboard, that's expected, not a hang. Subsequent boots (no pending migrations) are fast.

## Database (required — no SQLite/H2 fallback in production mode)

Keycloak has no embedded database in production mode (`start --optimized`, what this template
runs — `start-dev`'s in-memory H2 loses everything on restart and isn't used here). Deploy
`data-stores/relational/postgres` from this catalog as its own app first, then set `KC_DB_URL` /
`KC_DB_USERNAME` / `KC_DB_PASSWORD` in the dashboard (see `.env.example`) from the values that
deployment gives you — there's no dashboard "link" step on this tier. The DB driver itself
(`--db=postgres`) is baked into the image at build time via `kc.sh build`, which is why it's a
`Dockerfile` `RUN` step, not an env var.

## Deploying

Push this directory to a repo and connect it in the Bzync Cloud dashboard. Before going live:

1. Deploy Postgres (above) and set the `KC_DB_*` vars.
2. Leave `KC_BOOTSTRAP_ADMIN_PASSWORD=changeme` as-is — the platform replaces any literal
   `changeme` value with a generated random secret on first deploy. The first admin account is
   created for you automatically (native to the upstream image); find the generated password in
   the dashboard's Variables tab after deploy. It's **temporary** — Keycloak deletes it the first
   time you create a permanent admin in the master realm from the console.
3. Once you have a domain, set `KC_HOSTNAME` (see `.env.example`) so Keycloak's generated URLs
   (redirect URIs, realm metadata, emails) point at it instead of the container's own address.

## Health checks

The upstream image ships `curl`-free and `wget`-free (a minimal, deliberately stripped-down UBI
base) — `HEALTHCHECK` in `Dockerfile` speaks raw HTTP over bash's `/dev/tcp` instead, against
`/health/ready` on Keycloak's **management interface**, port `9000` — a separate port from the
main `8080` app traffic, not reachable through the same routes. `8080` still sorts lower than
`8443`/`9000` on its own, so it's already what Bzync Cloud's ingress targets for the public
dashboard URL — no `EXPOSE`-reordering trick was needed here, unlike the git-hosting templates in
this repo.

## Run locally

Needs a reachable Postgres on the same Docker network — `.env.example` defaults `KC_DB_URL` to
`jdbc:postgresql://db:5432/app`, matching a companion container aliased that way:

```bash
docker network create keycloak-dev-net
docker run -d --name keycloak-dev-db --network keycloak-dev-net --network-alias db \
  -e POSTGRES_DB=app -e POSTGRES_USER=app -e POSTGRES_PASSWORD=changeme postgres:16-alpine

docker build -t bzync-keycloak-dev .
docker run -d --name keycloak-dev --network keycloak-dev-net -p 8080:8080 -p 9000:9000 \
  --env-file .env.example bzync-keycloak-dev
```

Visit `http://localhost:8080` and log in as `admin` with `KC_BOOTSTRAP_ADMIN_PASSWORD`.

## Connecting apps to Keycloak

Create a **realm**, then a **client** for each app you want to protect, from the Keycloak admin
console — this isn't an env-var-driven flow the way database templates in this repo are. Each
client gets its own client ID/secret and OIDC discovery URL
(`/realms/<realm>/.well-known/openid-configuration`), same as you'd configure against Auth0, Okta,
or any other OIDC provider.

## Backups

All real state (realms, users, clients, sessions) lives in Postgres — this container itself holds
no persistent volume. Back up the Postgres deployment this points at; losing it loses everything.
