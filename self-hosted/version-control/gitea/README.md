# Gitea

A production-shaped, self-hosted Gitea instance — clone, push, and Bzync Cloud builds this
`Dockerfile` as-is, same as any other template. Unlike `database/*`, there's no managed Bzync
equivalent to fall back on: this deployment **is** your Gitea instance, and its `/data` volume
holds real, non-reproducible data (repos, issues, the database, LFS objects).

**Supported versions:** `1.23` (default) — set `GITEA_VERSION` as a build arg for others
**Default port:** `3000` (HTTP only — see "About SSH" below)

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
upstream filesystem specifically to drop that inherited `22` (see the comment in `Dockerfile`).
Git-over-SSH still runs inside the container, just not reachable through Bzync Cloud's
HTTP(S)-only ingress — clone over HTTPS instead:

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
