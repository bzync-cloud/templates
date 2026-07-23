# pgAdmin

A PostgreSQL GUI — clone, push, and Bzync Cloud builds this `Dockerfile` as-is, same as any
other template. Unlike Adminer, pgAdmin has its own login (`PGADMIN_DEFAULT_EMAIL` /
`PGADMIN_DEFAULT_PASSWORD`) separate from any Postgres server's credentials, and its
`/var/lib/pgadmin` volume persists that login plus any saved server connections and UI
preferences — not any actual database data, since pgAdmin is only ever a client.

**Supported versions:** `latest` (default) — set `PGADMIN_VERSION` as a build arg to pin one
**Default port:** `80`
**Supports:** PostgreSQL only (not MySQL — see `db-admin/phpmyadmin` or `db-admin/adminer` for
that)

## Deploying

Push this directory to a repo and connect it in the Bzync Cloud dashboard.

1. Set `PGADMIN_DEFAULT_EMAIL` to a real address you control and leave
   `PGADMIN_DEFAULT_PASSWORD=changeme` as-is — the platform replaces any literal `changeme` value
   with a generated random secret on first deploy. The container refuses to start without both
   set.
2. Once it's up, log in and add your Postgres server(s) from inside the UI (see below) — there's
   no env var that pre-fills this for you.

### Restrict access before going live

Unlike Adminer or phpMyAdmin, pgAdmin's own login is a real account, not just a pass-through to
the target database — that's a meaningfully stronger default. Still, once logged in, whatever
Postgres credentials you save inside pgAdmin are stored (encrypted, but decryptable by the app)
in `/var/lib/pgadmin`, so treat this instance itself as sensitive. On a public domain, also put
it behind Bzync Cloud's environment-level access control (Settings → Access) if you only need
your own team to reach it.

### Connecting to a linked database

Link a Postgres database in the Bzync Cloud dashboard, then add it as a server from pgAdmin's
UI: right-click **Servers → Register → Server**, and use the values the dashboard shows you —
`POSTGRES_HOST` as Host, `POSTGRES_PORT` as Port, `POSTGRES_DB` as Maintenance database,
`POSTGRES_USER` / `POSTGRES_PASSWORD` on the Connection tab. There's no `servers.json`
preload baked into this template (it would hard-code a specific database into the image), so
this is a one-time step per environment — pgAdmin remembers it afterward via the
`/var/lib/pgadmin` volume.

## Run locally

```bash
docker build -t bzync-pgadmin-dev .
docker run -d --name pgadmin-dev -p 8080:80 -v pgadmin-data:/var/lib/pgadmin \
  --env-file .env.example bzync-pgadmin-dev
```

Visit `http://localhost:8080` and log in with `admin@example.com` / the password you set for
`PGADMIN_DEFAULT_PASSWORD`.
