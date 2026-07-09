# Couchbase — Local Dev Reference

A local Couchbase container matching what Bzync Cloud Managed Databases (MDB) provisions in
production, so you can develop against the same engine version before linking the real thing.
`entrypoint.sh` mirrors the cluster-init / bucket-create / user-manage sequence that
`platform-cloud-mdb`'s provisioner runs against production instances, so the container comes up
with a usable cluster and bucket instead of the base image's unconfigured first-boot state.

**Supported versions:** `7.6.5` (default), `7.2.4`, `7.1.6`
**Default ports:** `8091-8096` (admin/services), `11210` (data)

## Run locally

```bash
docker build -t bzync-couchbase-dev .
docker run -d --name couchbase-dev \
  -p 8091-8096:8091-8096 -p 11210:11210 \
  --env-file .env.example bzync-couchbase-dev
```

Cluster init takes a few seconds on first boot. Once ready, the admin console is at
`http://localhost:8091` (login with `COUCHBASE_USERNAME` / `COUCHBASE_PASSWORD`), and the
`COUCHBASE_BUCKET` bucket already exists.

## Using a real managed database

This directory is a local dev stand-in — it isn't deployed by Bzync Cloud. Provision the real
thing from the dashboard: **Databases → Create → Couchbase**, then link it to your app's
environment. The platform injects these variables automatically:

```
DB_HOST
DB_PORT
DB_NAME
DB_USER
DB_PASSWORD
```

## Connecting from code

**Node (`couchbase`):**

```js
const couchbase = require("couchbase");
const cluster = await couchbase.connect(`couchbase://${process.env.DB_HOST}`, {
  username: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
});
const bucket = cluster.bucket(process.env.DB_NAME);
```

**Python (`couchbase`):**

```python
import os
from couchbase.cluster import Cluster
from couchbase.auth import PasswordAuthenticator

cluster = Cluster(
    f"couchbase://{os.environ['DB_HOST']}",
    authenticator=PasswordAuthenticator(os.environ["DB_USER"], os.environ["DB_PASSWORD"]),
)
bucket = cluster.bucket(os.environ["DB_NAME"])
```

**Go (`gocb`):**

```go
cluster, err := gocb.Connect("couchbase://"+os.Getenv("DB_HOST"), gocb.ClusterOptions{
    Username: os.Getenv("DB_USER"),
    Password: os.Getenv("DB_PASSWORD"),
})
bucket := cluster.Bucket(os.Getenv("DB_NAME"))
```
