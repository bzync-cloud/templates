# Zitadel

A deployable Zitadel template — clone, push, and Bzync Cloud builds this `Dockerfile` as-is, same
as any other template. Zitadel is a cloud-native identity provider: SSO, OIDC/OAuth2, SAML,
multi-tenancy (organizations) built in from the start, and a modern gRPC/REST API. There's no
managed Bzync equivalent to fall back on — this deployment **is** your identity provider, and
every other app you protect with it depends on it being up.

**Supported version:** `v4.16.1` (default) — set `ZITADEL_VERSION` as a build arg for others
**Default port:** `8080` (HTTP)

## Database (required — no SQLite fallback)

Zitadel has no embedded database. Deploy `data-stores/relational/postgres` from this catalog as
its own app first, then set the `ZITADEL_DATABASE_POSTGRES_*` vars in the dashboard (see
`.env.example`) from the values that deployment gives you — there's no dashboard "link" step on
this tier. Using the same username for both the `USER` and `ADMIN` credential pairs (as this
repo's Postgres template's single app-user setup naturally gives you) makes Zitadel skip a
separate `CREATE USER`/`GRANT` step it would otherwise attempt with elevated Postgres privileges
you don't have here.

**Deploy Postgres first and let it fully boot before deploying this template.** Unlike authentik
and Keycloak elsewhere in this repo, Zitadel's `start-from-init` command (what this template runs)
fails fast and exits on its very first database connection attempt instead of retrying — confirmed
by testing: starting both containers at once reproducibly crashes Zitadel with `dial tcp ...:5432:
connect: connection refused` before it ever binds its HTTP port, because Postgres's own first-boot
initialization hadn't finished accepting connections yet. A single crash like this isn't fatal on
its own — the platform restarts a crashed container automatically, and the retry succeeds once
Postgres is actually up — but deploying Postgres first (and confirmed reachable) avoids the crash
entirely rather than depending on the automatic restart to paper over it.

## Deploying

Push this directory to a repo and connect it in the Bzync Cloud dashboard. Before going live:

1. Deploy Postgres (above) and set the `ZITADEL_DATABASE_POSTGRES_*` vars.
2. Generate a real `ZITADEL_MASTERKEY` — it must be **exactly 32 characters**, and Zitadel uses
   it to encrypt data at rest:
   ```bash
   openssl rand -base64 32 | head -c 32
   ```
   Unlike other secrets in this repo, this one can't use the "changeme" placeholder-replacement
   convention (8 characters, and the platform's generated replacement isn't guaranteed to be
   exactly 32) — set it explicitly.
3. Set `ZITADEL_FIRSTINSTANCE_ORG_HUMAN_PASSWORD` to a value meeting Zitadel's password
   complexity policy (upper + lower case, a digit, and a symbol). **The repo-standard "changeme"
   placeholder fails this outright** — confirmed by testing: a fresh deploy with
   `ZITADEL_FIRSTINSTANCE_ORG_HUMAN_PASSWORD=changeme` crashes first-boot setup with
   `Errors.User.PasswordComplexityPolicy.HasUpper` instead of just warning, the same trap
   `GITLAB_ROOT_PASSWORD` avoids elsewhere in this repo. Leaving it unset entirely also boots
   fine (also confirmed by testing) — the first admin account (`admin`, or whatever you set
   `ZITADEL_FIRSTINSTANCE_ORG_HUMAN_USERNAME` to) just has no usable password until you set one
   from the console's password-reset flow.
4. Once you have a domain, set `ZITADEL_EXTERNALDOMAIN` (see `.env.example`) so Zitadel's
   generated URLs (OIDC discovery, redirect URIs, emails) point at it and Host-header validation
   passes.

## Health checks

The upstream image is fully distroless — no shell, no `curl`/`wget`/`nc`, not even `env`, just a
single static Go binary. This template ships with **no `Dockerfile` `HEALTHCHECK`**: the one
candidate that survives exec form without a shell, the binary's own `zitadel ready` subcommand,
tested as permanently failing (`Error: not ready`) in this deployment shape even while the real
HTTP endpoints (`/debug/healthz`, `/ui/console`) served `200` the entire time — it checks
something beyond plain HTTP reachability that never resolved here. Bzync Cloud's own ingress
health check still probes the container over real HTTP on port `8080` regardless of whether a
Docker-level `HEALTHCHECK` is declared, so this doesn't affect deploy health gating on the
platform — only `docker inspect`'s own `.State.Health` field, which local `docker run` users
won't see populated.

## Run locally

Needs a reachable Postgres on the same Docker network — `.env.example` defaults
`ZITADEL_DATABASE_POSTGRES_HOST` to `db`, matching a companion container aliased that way:

```bash
docker network create zitadel-dev-net
docker run -d --name zitadel-dev-db --network zitadel-dev-net --network-alias db \
  -e POSTGRES_DB=app -e POSTGRES_USER=app -e POSTGRES_PASSWORD=changeme postgres:16-alpine

docker build -t bzync-zitadel-dev .
docker run -d --name zitadel-dev --network zitadel-dev-net -p 8080:8080 \
  --env-file .env.example bzync-zitadel-dev
```

Visit `http://localhost:8080/ui/console` and log in as `admin` with whatever you set
`ZITADEL_FIRSTINSTANCE_ORG_HUMAN_PASSWORD` to.

## Connecting apps to Zitadel

Create an **organization** and a **project** with one or more **applications** inside it (OIDC,
SAML, or API) from the Zitadel console — this isn't an env-var-driven flow the way database
templates in this repo are. Each application gets its own client ID/secret and OIDC discovery URL
(`/.well-known/openid-configuration`), same as you'd configure against Auth0, Okta, or any other
OIDC provider.

## Backups

All real state (organizations, users, projects, applications, sessions) lives in Postgres — this
container itself holds no persistent volume. Back up the Postgres deployment this points at;
losing it loses everything.
