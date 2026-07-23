# MySQL

A deployable MySQL template — clone, push, and Bzync Cloud builds this `Dockerfile` as-is, same
as any other template. It matches the exact engine/version Bzync Cloud's production Managed
Databases (MDB) provisions — but this tier has no managed database service of its own (mdb was
removed here; see the workspace root `README.md`), so it doubles as a local dev container rather
than a stand-in for a real managed instance.

**Supported versions:** `8.0` (default), `5.7`
**Default port:** `3306`

## Deploying

Push this directory to a repo and connect it in the Bzync Cloud dashboard like any other
template — it builds and runs as a single-container service. Set `MYSQL_DATABASE`, `MYSQL_USER`,
and `MYSQL_PASSWORD` in the dashboard for the environment (see `.env.example`). A deployed
instance here is a plain container, not a managed one — no automatic replication, backups, or
HA, and no managed alternative to fall back to on this tier: this deployment *is* the database
for any app here that needs MySQL.

## Run locally

```bash
docker build -t bzync-mysql-dev .
docker run -d --name mysql-dev -p 3306:3306 --env-file .env.example bzync-mysql-dev
```

Connect with the `mysql` client:

```bash
mysql -h 127.0.0.1 -P 3306 -u app -pchangeme app
```

## Connecting another app to this database

There's no dashboard "link" step on this tier — deploy this template as its own app, then set
matching connection env vars on whichever app needs to reach it (its internal address, plus the
`MYSQL_DATABASE`/`MYSQL_USER`/`MYSQL_PASSWORD` you set above):

```
MYSQL_HOST
MYSQL_PORT
MYSQL_DATABASE
MYSQL_USER
MYSQL_PASSWORD
DATABASE_URL   # mysql://user:password@host:port/dbname
```

## Connecting from code

**Node (`mysql2`):**

```js
import mysql from "mysql2/promise";
const conn = await mysql.createConnection(process.env.DATABASE_URL);
```

**Python (`PyMySQL`):**

```python
import os, pymysql
conn = pymysql.connect(
    host=os.environ["MYSQL_HOST"], port=int(os.environ["MYSQL_PORT"]),
    user=os.environ["MYSQL_USER"], password=os.environ["MYSQL_PASSWORD"],
    database=os.environ["MYSQL_DATABASE"],
)
```

**Go (`database/sql` + `go-sql-driver/mysql`):**

```go
db, err := sql.Open("mysql", os.Getenv("MYSQL_USER")+":"+os.Getenv("MYSQL_PASSWORD")+
    "@tcp("+os.Getenv("MYSQL_HOST")+":"+os.Getenv("MYSQL_PORT")+")/"+os.Getenv("MYSQL_DATABASE"))
```
