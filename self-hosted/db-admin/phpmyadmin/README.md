# phpMyAdmin

A MySQL/MariaDB GUI — clone, push, and Bzync Cloud builds this `Dockerfile` as-is, same as any
other template. phpMyAdmin is stateless: it has no database or config of its own, holds no
credentials, and needs no persistent volume. Every "login" is a live connection attempt against
a real MySQL/MariaDB server using a real username and password.

**Supported versions:** `5.2` (default) — set `PHPMYADMIN_VERSION` as a build arg for others
**Default port:** `80`
**Supports:** MySQL, MariaDB (not Postgres — see `db-admin/pgadmin` or `db-admin/adminer` for that)

## Deploying

Push this directory to a repo and connect it in the Bzync Cloud dashboard. There's no install
step and no admin account to create — phpMyAdmin is ready as soon as the container is healthy.

### Restrict access before going live

phpMyAdmin has no login of its own beyond the target database's real credentials — anyone who
reaches the URL gets a working login form. That's fine on an internal/VPN-only environment; on a
public domain, put it behind:

- Bzync Cloud's environment-level access control (Settings → Access), if you only need your own
  team to reach it, or
- A strong, unique password on the database account you intend to use with it — phpMyAdmin
  itself doesn't rate-limit or lock out failed login attempts.

Don't leave a production database's admin credentials as the ones you log in with on a
publicly-reachable instance.

### Connecting to a linked database

Link a MySQL or MariaDB database in the Bzync Cloud dashboard, then set `PMA_HOST` (and
`PMA_PORT` if non-default) from the values it shows you — see `.env.example`. This pre-fills and
locks the login form to that one server; username and password are still entered by hand each
time, phpMyAdmin never stores them. Leave `PMA_ARBITRARY=1` (the default) instead if you want a
free-text server field to reach more than one database from the same instance.

## Run locally

```bash
docker build -t bzync-phpmyadmin-dev .
docker run -d --name phpmyadmin-dev -p 8080:80 --env-file .env.example bzync-phpmyadmin-dev
```

Visit `http://localhost:8080` and log in against any MySQL/MariaDB reachable from the
container — for a local database also running in Docker, use `--link` or a shared `--network`
and the container name as `PMA_HOST`.
