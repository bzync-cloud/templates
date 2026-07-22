# Gitea

A production-shaped, self-hosted Gitea instance — clone, push, and Bzync Cloud builds this
`Dockerfile` as-is, same as any other template. Unlike `database/*`, there's no managed Bzync
equivalent to fall back on: this deployment **is** your Gitea instance, and its `/data` volume
holds real, non-reproducible data (repos, issues, the database, LFS objects).

**Supported versions:** `1.23` (default) — set `GITEA_VERSION` as a build arg for others
**Default port:** `3000` (HTTP — see "About SSH" below for git-over-SSH)

## Deploying

Push this directory to a repo and connect it in the Bzync Cloud dashboard. Before going live:

1. Set `GITEA__server__ROOT_URL` and `GITEA__server__DOMAIN` to your real domain (see
   `.env.example`) — Gitea uses these to generate clone URLs and links in emails.
2. Leave `GITEA__security__SECRET_KEY=changeme` as-is — the platform replaces any literal
   `changeme` value with a generated random secret on first deploy. `INTERNAL_TOKEN` and the
   OAuth2 `JWT_SECRET` don't need setting at all — Gitea generates and persists both to
   `/data/gitea/conf/app.ini` itself on first boot.
3. The first admin account is created for you automatically — see below.

### About SSH

The image only exposes port `3000`. Bzync Cloud's ingress and health checks target the
lowest-numbered `EXPOSE`d port in the built image, and the upstream `gitea/gitea` image bakes in
port `22` alongside `3000` — if both were exposed, HTTP traffic would get silently routed to the
SSH port instead of the web server. This Dockerfile rebuilds from `scratch` on top of the
upstream filesystem specifically to drop that inherited `22` (see the comment in `Dockerfile`),
which is still correct and unrelated to the feature below — dropping the image's own `EXPOSE 22`
only affects Traefik's port autodetection for HTTP, not whether SSH can be reached.

Real `git@host:owner/repo.git` clones need the project's **"Enable Git SSH access"** toggle
(Project → Git SSH in the dashboard — requires a plan with that feature). Enabling it allocates a
dedicated port and binds it straight to the container's SSH port, bypassing the HTTP(S) ingress
entirely — it works whether or not this Dockerfile exposes `22`. Once enabled, the dashboard shows
the exact command:

```bash
git clone ssh://git@your-app.app.bzync.cloud:20005/owner/repo.git
```

Also set `GITEA__server__SSH_DOMAIN`/`GITEA__server__SSH_PORT` in `.env.example` to the same
host/port shown there — without them, Gitea's own generated clone URLs (shown in its web UI)
still advertise `localhost`, even though the SSH connection itself works. HTTPS clone always
works regardless, with or without this toggle:

```bash
git clone https://your-domain.example.com/owner/repo.git
```

### Creating the first admin account

`GITEA__service__DISABLE_REGISTRATION=true` by default (production-hardened: no open sign-up),
so there's no install wizard or sign-up form to create the first user. Instead,
`bzync-entrypoint.sh` wraps the upstream image's entrypoint and creates the account itself from
`GITEA_ADMIN_USERNAME` / `GITEA_ADMIN_PASSWORD` / `GITEA_ADMIN_EMAIL` (see `.env.example`) once
the container has booted — it polls for `app.ini` and retries past the `database is locked`
window that happens mid-migration, so there's nothing to babysit. Leaving
`GITEA_ADMIN_PASSWORD=changeme` in place gets you a strong generated password the same way
`SECRET_KEY` does; find it in the dashboard's Variables tab after the first deploy. It's safe to
leave this running on every boot — it no-ops once that username already exists.

To skip this and create the account yourself instead, unset `GITEA_ADMIN_USERNAME` or
`GITEA_ADMIN_PASSWORD` and run:

```bash
docker exec -u git <container> gitea admin user create \
  --username admin --password 'a-strong-password' \
  --email admin@your-domain.example.com --admin \
  --config /data/gitea/conf/app.ini
```

If you're deploying without shell access to the running container, use Gitea's own admin panel
after temporarily flipping `GITEA__service__DISABLE_REGISTRATION=false`, register the first
account, then flip it back and redeploy.

### Deploy strategy: Standard vs. Blue-Green/Rolling

Set this project's deploy strategy under Project → Settings → Deploy Strategy.

**Standard** works out of the box with no extra configuration — it always destroys the old
container before starting the new one, so only one Gitea instance ever touches `/data` at a time.

**Blue-Green and Rolling** briefly run the new instance alongside the old one against the *same*
`/data` volume — that overlap is the entire point of both strategies (zero-downtime cutover). Out
of the box this fails: Gitea's default queue backend (LevelDB, under `/data/gitea/queues`) takes
an exclusive process-level file lock, so the new instance can't acquire it while the old one is
still running, and crash-loops on a fatal `unable to lock level db` error until the deploy times
out and rolls back — you'll see `health check timed out: 0/1 containers healthy after 60s` in the
build log with no other explanation.

To use Blue-Green or Rolling, deploy `database/redis` from this catalog as its own app, then set
(see `.env.example`):

```
GITEA__queue__TYPE=redis
GITEA__queue__CONN_STR=redis://:<REDIS_PASSWORD>@<REDIS_HOST>:6379/0
```

This moves the queue off the local, single-writer LevelDB file onto Redis, which both instances
can connect to concurrently. Note this doesn't make concurrent instances fully equivalent to a
real HA setup — SQLite still only allows one writer at a time, so a real write landing on both
instances in the same instant (rare, given the overlap window is seconds) can hit a transient
`database is locked` retry; Gitea sets a busy-timeout by default so this resolves itself rather
than failing outright. For that residual risk to go away entirely, switch
`GITEA__database__DB_TYPE` to `postgres` too (see "SQLite vs. Postgres" below).

## Run locally

```bash
docker build -t bzync-gitea-dev .
docker run -d --name gitea-dev -p 3000:3000 -v gitea-data:/data --env-file .env.example bzync-gitea-dev
```

Visit `http://localhost:3000` — with the defaults above, registration is disabled, so create the
first admin with the `docker exec` command above before logging in.

## SQLite vs. Postgres

The default (`GITEA__database__DB_TYPE=sqlite3`) needs no separate database and is fine for
small teams — the whole instance's state lives in `/data`. For heavier or multi-instance use,
deploy `database/postgres` from this catalog as its own app, then switch to the commented-out
Postgres block in `.env.example` using the values you set there (no dashboard linking on this
tier). Gitea migrates the schema automatically on
next boot against the new database — it does **not** migrate your existing SQLite data across;
plan a `gitea dump`/restore if you're moving an instance with real history.

## Backups

Everything that matters lives under `/data`: the SQLite DB (or just config/repos if using
Postgres), `conf/app.ini` (including the auto-generated secrets), Git repository data, LFS
objects, and avatars. Losing the volume loses the instance. Gitea has a built-in export:

```bash
docker exec -u git <container> gitea dump -c /data/gitea/conf/app.ini
```
