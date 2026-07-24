# Vikunja

A production-shaped, self-hosted Vikunja instance — clone, push, and Bzync Cloud builds this
`Dockerfile` as-is, same as any other template. Unlike `database/*`, there's no managed Bzync
equivalent to fall back on: this deployment **is** your Vikunja instance, and its `/db` and
`/app/vikunja/files` volumes hold real, non-reproducible data (tasks, projects, users, and any
uploaded attachments).

**Supported versions:** `latest` (default) — set `VIKUNJA_VERSION` as a build arg to pin one
**Default port:** `3456`

## Deploying

Push this directory to a repo and connect it in the Bzync Cloud dashboard. Before going live:

1. Set `VIKUNJA_SERVICE_PUBLICURL` to your real domain (see `.env.example`) — Vikunja refuses to
   start without it (CORS is on by default) and uses it to build links in emails and the
   frontend's API base URL.
2. Leave `VIKUNJA_SERVICE_SECRET=changeme` as-is — the platform replaces any literal `changeme`
   value with a generated random secret on first deploy.
3. Register your first account, then leave `VIKUNJA_SERVICE_ENABLEREGISTRATION=false` (the
   default) to close sign-up back up — or leave it `true` if you want it to stay open.

### About the base image

The upstream `vikunja/vikunja` image is a single static binary on a shell-less, distroless-style
base running as a non-root user — there's no `sh` to exec into for debugging, and that same user
can't create new directories directly under `/` or `/app/vikunja` at runtime. This `Dockerfile`
pre-creates and `chown`s `/db` and `/app/vikunja/files` in a throwaway `busybox` build stage and
copies them in with the right ownership, which is also why both are declared as `VOLUME`s — so a
fresh anonymous volume at either path inherits that ownership instead of defaulting to root and
failing every write.

### Deploy strategy: Standard vs. Blue-Green/Rolling

Set this project's deploy strategy under Project → Settings → Deploy Strategy.

**Standard** works out of the box with no extra configuration — it always destroys the old
container before starting the new one, so only one Vikunja instance ever touches `/db` at a time.

**Blue-Green and Rolling** briefly run the new instance alongside the old one against the *same*
`/db` volume — that overlap is the entire point of both strategies (zero-downtime cutover). The
risk here is the default database itself: SQLite only allows one writer at a time, so a real write
landing on both instances in the same instant (rare, given the overlap window is seconds) can hit a
transient "database is locked" error. Whether that resolves itself with a retry or surfaces as a
failed request depends on Vikunja's SQLite driver settings, which this template doesn't tune — for
that risk to go away entirely, switch to Postgres or MySQL instead (see "SQLite vs. Postgres/MySQL"
below), which handle concurrent writers natively. Until then, stick to Standard.

## Run locally

```bash
docker build -t bzync-vikunja-dev .
docker run -d --name vikunja-dev -p 3456:3456 \
  -e VIKUNJA_SERVICE_PUBLICURL=http://localhost:3456/ \
  -e VIKUNJA_SERVICE_SECRET=changeme \
  bzync-vikunja-dev
```

Visit `http://localhost:3456` and register the first account — data persists in the two
anonymous volumes Docker creates for `/db` and `/app/vikunja/files`; add explicit `-v` flags if
you want named ones instead.

## SQLite vs. Postgres/MySQL

The default needs no separate database — the whole instance's state lives in `/db` (SQLite) and
`/app/vikunja/files` (attachments). Fine for solo or small-team use. For heavier or
multi-instance use, deploy `database/postgres` or `database/mysql` from this catalog as its own
app, and set the `VIKUNJA_DATABASE_*` block in `.env.example` from the values you configured
there (no dashboard linking on this tier). Vikunja migrates the
schema automatically on next boot against the new database — it does **not** migrate your
existing SQLite data across; use `vikunja dump` / `vikunja restore` if you're moving an instance
with real history.

## Backups

```bash
docker exec <container> /app/vikunja/vikunja dump
```

Writes a zip containing the config, database, and files to the container's working directory —
copy it out with `docker cp` before it's lost to a redeploy. If you've switched to Postgres/MySQL,
back up that database separately too (Vikunja's own `dump` only captures SQLite).
