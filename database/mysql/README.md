# MySQL — Local Dev Reference

A local MySQL container matching what Bzync Cloud Managed Databases (MDB) provisions in
production, so you can develop against the same engine version before linking the real thing.

**Supported versions:** `8.0` (default), `5.7`
**Default port:** `3306`

## Run locally

```bash
docker build -t bzync-mysql-dev .
docker run -d --name mysql-dev -p 3306:3306 --env-file .env.example bzync-mysql-dev
```

Connect with the `mysql` client:

```bash
mysql -h 127.0.0.1 -P 3306 -u app -pchangeme app
```

## Using a real managed database

This directory is a local dev stand-in — it isn't deployed by Bzync Cloud. Provision the real
thing from the dashboard: **Databases → Create → MySQL**, then link it to your app's
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
