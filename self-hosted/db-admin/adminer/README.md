# Adminer

A single-file database GUI — clone, push, and Bzync Cloud builds this `Dockerfile` as-is, same
as any other template. Adminer is stateless: it has no database or config of its own, holds no
credentials, and needs no persistent volume. Every "login" is just a live connection attempt
against whatever host you type into the form — the same fields as any DB client.

**Supported versions:** `5` (default) — set `ADMINER_VERSION` as a build arg for others
**Default port:** `8080`
**Supports:** MySQL/MariaDB, PostgreSQL, SQLite, MS SQL, Oracle, Elasticsearch, ClickHouse, and more

## Deploying

Push this directory to a repo and connect it in the Bzync Cloud dashboard. There's no install
step and no admin account to create — Adminer is ready as soon as the container is healthy.

### Restrict access before going live

Adminer has no login of its own beyond the target database's real credentials — anyone who
reaches the URL gets a working login form pointed at whatever database server they choose to
type in. That's fine on an internal/VPN-only environment; on a public domain, put it behind:

- Bzync Cloud's environment-level access control (Settings → Access), if you only need your own
  team to reach it, or
- A strong, unique password on the database account you intend to use with Adminer — Adminer
  itself doesn't rate-limit or lock out failed login attempts.

Don't leave a production database's admin credentials as the ones you type into a
publicly-reachable Adminer instance.

### Connecting to a linked database

Link a database in the Bzync Cloud dashboard, then use the values it shows you as Adminer's
login fields:

| Adminer field | Value |
|---|---|
| System | `PostgreSQL` or `MySQL` (matches what you linked) |
| Server | `POSTGRES_HOST:POSTGRES_PORT` or `MYSQL_HOST:MYSQL_PORT` |
| Username | `POSTGRES_USER` / `MYSQL_USER` |
| Password | `POSTGRES_PASSWORD` / `MYSQL_PASSWORD` |
| Database | `POSTGRES_DB` / `MYSQL_DATABASE` |

There's no `ADMINER_DEFAULT_SERVER` env var in the upstream image to pre-fill these — the
`login-servers` plugin can do it, but it takes constructor arguments, so it needs a hand-written
file rather than the `ADMINER_PLUGINS` env var (see `.env.example`).

## Run locally

```bash
docker build -t bzync-adminer-dev .
docker run -d --name adminer-dev -p 8080:8080 bzync-adminer-dev
```

Visit `http://localhost:8080` and log in against any database reachable from the container —
for a local Postgres also running in Docker, use `--link` or a shared `--network` and the
container name as the server host.

## Appearance and plugins

`ADMINER_DESIGN` picks a login/UI theme (default `pepa-linha`); see `.env.example` for the full
list shipped in the image. `ADMINER_PLUGINS` auto-enables plugins with no required constructor
arguments — anything more advanced (predefined server lists, IP allowlisting, SSO) needs a
custom `plugins-enabled/*.php` file baked into a derived image, since there's no volume to drop
one into at runtime.
