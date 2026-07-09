# MariaDB — Local Dev Reference

A local MariaDB container matching what Bzync Cloud Managed Databases (MDB) provisions in
production, so you can develop against the same engine version before linking the real thing.
Wire-compatible with MySQL clients and drivers.

**Supported versions:** `11` (default), `10.11`
**Default port:** `3306`

## Run locally

```bash
docker build -t bzync-mariadb-dev .
docker run -d --name mariadb-dev -p 3306:3306 --env-file .env.example bzync-mariadb-dev
```

Connect with the `mysql` client:

```bash
mysql -h 127.0.0.1 -P 3306 -u app -pchangeme app
```

## Using a real managed database

This directory is a local dev stand-in — it isn't deployed by Bzync Cloud. Provision the real
thing from the dashboard: **Databases → Create → MariaDB**, then link it to your app's
environment. The platform injects these variables automatically:

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
