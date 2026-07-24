# Focalboard

A production-shaped, self-hosted Focalboard instance (Trello/Notion-style boards) — clone,
push, and Bzync Cloud builds this `Dockerfile` as-is, same as any other template. Unlike
`database/*`, there's no managed Bzync equivalent to fall back on: this deployment **is** your
Focalboard instance, and its `/opt/focalboard/data` volume holds real, non-reproducible data
(boards, cards, users, and any uploaded file attachments).

**Note:** Mattermost archived standalone Focalboard in favor of "Boards" built into Mattermost
itself. This template still works and is a fine lightweight option if you don't want all of
Mattermost, but it isn't receiving new upstream releases.

**Supported versions:** `latest` (default) — set `FOCALBOARD_VERSION` as a build arg to pin one
**Default port:** `8000`

## Deploying

Push this directory to a repo and connect it in the Bzync Cloud dashboard.

1. Set `FOCALBOARD_SERVERROOT` to your real domain (see `.env.example`) once one is attached.
2. Register your first account at `/register` right after the first deploy.

### Restrict access before going live

Focalboard has no setting to close self-registration — `/register` is reachable to anyone who
finds the URL, for as long as the instance is up. If you need to lock this down, put it behind
Bzync Cloud's environment-level access control (Settings → Access) before anyone else can find
the URL, or register your own account immediately after first boot and treat the window before
that as the exposure to close quickly.

### About the base image

The upstream `mattermost/focalboard` image only reads `config.json` (plus a couple of database
CLI flags) — it has no environment-variable config of its own. `start.sh` (this image's
entrypoint) patches that file in place from `FOCALBOARD_SERVERROOT` and a linked database's
`DB_*` vars before handing off to `focalboard-server`, so the usual dashboard env var workflow
still applies.

### Deploy strategy: Standard vs. Blue-Green/Rolling

Set this project's deploy strategy under Project → Settings → Deploy Strategy.

**Standard** works out of the box with no extra configuration — it always destroys the old
container before starting the new one, so only one Focalboard instance ever touches
`/opt/focalboard/data` at a time.

**Blue-Green and Rolling** briefly run the new instance alongside the old one against the *same*
`/opt/focalboard/data` volume — that overlap is the entire point of both strategies (zero-downtime
cutover). The risk here is the default database itself: SQLite only allows one writer at a time,
so a real write landing on both instances in the same instant (rare, given the overlap window is
seconds) can produce a "database is locked" error. For that risk to go away entirely, switch to
Postgres instead (see "SQLite vs. Postgres" below), which handles concurrent writers natively.
Until then, stick to Standard.

## Run locally

```bash
docker build -t bzync-focalboard-dev .
docker run -d --name focalboard-dev -p 8000:8000 --env-file .env.example bzync-focalboard-dev
```

Visit `http://localhost:8000` and register the first account. Data persists in an anonymous
volume Docker creates for `/opt/focalboard/data` — add an explicit `-v` flag if you want a named
one instead.

## SQLite vs. Postgres

The default needs no separate database — the whole instance's state lives in
`/opt/focalboard/data` (SQLite) plus uploaded files. Fine for solo or small-team use. For
heavier or multi-instance use, deploy `database/postgres` from this catalog as its own app, set
`DB_HOST`/`DB_PORT`/`DB_NAME`/`DB_USER`/`DB_PASSWORD` here from the values you configured there
(no dashboard linking on this tier), and `start.sh` picks it up automatically (see
`.env.example`). Focalboard
migrates the schema automatically on next boot against the new database — it does **not**
migrate your existing SQLite data across.
