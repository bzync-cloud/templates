# Gogs

A production-shaped, self-hosted Gogs instance — clone, push, and Bzync Cloud builds this
`Dockerfile` as-is, same as any other template. Gogs is the lightweight, original project that
Gitea itself was forked from in 2016 — smaller and simpler than Gitea/Forgejo, but without their
newer feature set (no built-in Actions/CI, no env-to-config system). Unlike `database/*`, there's
no managed Bzync equivalent to fall back on: this deployment **is** your Gogs instance, and its
`/data` volume holds real, non-reproducible data (repos, the database, config).

**Supported versions:** `0.13` (default) — set `GOGS_VERSION` as a build arg for others
**Default port:** `3000` (HTTP only — see "About SSH" below)

## Deploying

Push this directory to a repo and connect it in the Bzync Cloud dashboard. Before going live:

1. Set `GOGS_DOMAIN` and `GOGS_ROOT_URL` to your real domain (see `.env.example`).
2. Leave `GOGS_SECRET_KEY=changeme` as-is — the platform replaces any literal `changeme` value
   with a generated random secret on first deploy.
3. The first admin account is created for you automatically — see below.

Unlike Gitea/Forgejo's `GITEA__` environment variables, Gogs has no env-to-config system of its
own. This template's `entrypoint.sh` renders `/data/gogs/conf/app.ini` from the `GOGS_*`
variables using `envsubst`, standing in for Gogs' interactive install wizard — but **only once**,
on first boot. Changing a `GOGS_*` value after that has no effect unless you also delete the
rendered `app.ini` from the volume, which discards `SECRET_KEY` along with everything else unless
you keep it the same.

### About SSH

The image only exposes port `3000`. Bzync Cloud's ingress and health checks target the
lowest-numbered `EXPOSE`d port in the built image, and the upstream `gogs/gogs` image bakes in
port `22` alongside `3000` — if both were exposed, HTTP traffic would get silently routed to the
SSH port instead of the web server. This Dockerfile rebuilds from `scratch` on top of the
upstream filesystem specifically to drop that inherited `22` (see the comment in `Dockerfile`).
Gogs' own built-in SSH server is also disabled (`START_SSH_SERVER=false`, in favor of the real
OpenSSH daemon the base image already runs) — either way, SSH isn't reachable through Bzync
Cloud's HTTP(S)-only ingress. Clone over HTTPS instead:

```bash
git clone https://your-domain.example.com/owner/repo.git
```

### Creating the first admin account

`GOGS_DISABLE_REGISTRATION=true` by default (production-hardened: no open sign-up), so there's no
sign-up form to create the first user. Instead, `entrypoint.sh` creates the account itself from
`GOGS_ADMIN_USERNAME` / `GOGS_ADMIN_PASSWORD` / `GOGS_ADMIN_EMAIL` (see `.env.example`) once the
instance is up — it polls for `app.ini` and retries past Gogs' first-boot migration window, so
there's nothing to babysit. Leaving `GOGS_ADMIN_PASSWORD=changeme` in place gets you a strong
generated password the same way `SECRET_KEY` does; find it in the dashboard's Variables tab after
the first deploy. `admin` is a reserved username in Gogs, hence the default of `bzyncadmin` — the
script refuses to run rather than loop forever if you set it to `admin` anyway. It's safe to leave
this running on every boot — it no-ops once that username already exists.

To skip this and create the account yourself instead, unset `GOGS_ADMIN_USERNAME` or
`GOGS_ADMIN_PASSWORD` and run (username must not be `admin`):

```bash
docker exec -u git <container> /app/gogs/gogs admin create-user \
  --name bzyncadmin --password 'a-strong-password' \
  --email admin@your-domain.example.com --admin \
  --config /data/gogs/conf/app.ini
```

### The REST API needs a token, not your password

Git-over-HTTP (`git clone`/`git push`) accepts your account username and password directly. The
REST API (`/api/v1/...`) does **not** — `curl -u user:password` against the API returns `401`.
Generate a personal access token from **Your Settings → Applications** in the web UI (or the
`gogs admin` CLI), then authenticate with:

```bash
curl -H "Authorization: token <token>" https://your-domain.example.com/api/v1/user
```

## Run locally

```bash
docker build -t bzync-gogs-dev .
docker run -d --name gogs-dev -p 3000:3000 -v gogs-data:/data --env-file .env.example bzync-gogs-dev
```

Visit `http://localhost:3000` — with the defaults above, registration is disabled, so create the
first admin with the `docker exec` command above before logging in.

## SQLite vs. Postgres

The default (`GOGS_DB_TYPE=sqlite3`) needs no separate database and is fine for small teams — the
whole instance's state lives in `/data`. For heavier or multi-instance use, deploy
`database/postgres` from this catalog as its own app, then switch to the commented-out Postgres
block in `.env.example` using the values you set there (no dashboard linking on this tier —
remember this only takes effect on a fresh `/data` volume, since `app.ini` is rendered once, see
"Deploying" above).

## Backups

Everything that matters lives under `/data`: the SQLite DB (or just config/repos if using
Postgres), `conf/app.ini` (including `SECRET_KEY`), and Git repository data. Losing the volume
loses the instance. Gogs has a built-in export:

```bash
docker exec -u git <container> /app/gogs/gogs backup -c /data/gogs/conf/app.ini
```
