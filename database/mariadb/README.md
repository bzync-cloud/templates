# MariaDB

A deployable MariaDB template — clone, push, and Bzync Cloud builds this `Dockerfile` as-is,
same as any other template. It also matches the exact engine/version Bzync Cloud Managed
Databases (MDB) provisions in production, so it doubles as a local dev container.
Wire-compatible with MySQL clients and drivers.

**Supported versions:** `11` (default), `10.11`
**Default port:** `3306`

## Deploying

Push this directory to a repo and connect it in the Bzync Cloud dashboard like any other
template — it builds and runs as a single-container service. Set `MARIADB_DATABASE`,
`MARIADB_USER`, and `MARIADB_PASSWORD` in the dashboard for the environment (see
`.env.example`). A deployed instance here is a plain container, not a managed one — no
automatic replication, backups, or HA. For production data, provision through
**Databases → Create → MariaDB** (MDB) instead and link it to your app's environment.

## Run locally

```bash
docker build -t bzync-mariadb-dev .
docker run -d --name mariadb-dev -p 3306:3306 --env-file .env.example bzync-mariadb-dev
```

Connect with the `mysql` client:

```bash
mysql -h 127.0.0.1 -P 3306 -u app -pchangeme app
```

## Using MDB instead

If you provision a real managed MariaDB from **Databases → Create → MariaDB** and link it to
your app's environment, the platform injects these variables automatically:

```
MYSQL_HOST
MYSQL_PORT
MYSQL_DATABASE
MYSQL_USER
MYSQL_PASSWORD
DATABASE_URL   # mysql://user:password@host:port/dbname
```

## Connecting from code

Any MySQL-compatible driver works unchanged — see `../mysql/README.md` for Node, Python, and Go
snippets.
