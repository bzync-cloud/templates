# Couchbase

A deployable Couchbase template — clone, push, and Bzync Cloud builds this `Dockerfile` as-is,
same as any other template. It also matches the exact engine/version Bzync Cloud Managed
Databases (MDB) provisions in production, so it doubles as a local dev container.
`entrypoint.sh` mirrors the cluster-init / bucket-create / user-manage sequence that
`platform-cloud-mdb`'s provisioner runs against production instances, so the container comes up
with a usable cluster and bucket instead of the base image's unconfigured first-boot state.

**Supported versions:** `7.6.5` (default), `7.2.4`, `7.1.6`
**Default ports:** `8091-8096` (admin/services), `11210` (data)

## Deploying

Push this directory to a repo and connect it in the Bzync Cloud dashboard like any other
template — it builds and runs as a single-container service. Set `COUCHBASE_BUCKET`,
`COUCHBASE_USERNAME`, and `COUCHBASE_PASSWORD` in the dashboard for the environment (see
`.env.example`). A deployed instance here is a plain container, not a managed one — no
automatic replication, backups, or HA. For production data, provision through
**Databases → Create → Couchbase** (MDB) instead and link it to your app's environment.

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

## Using MDB instead

If you provision a real managed Couchbase from **Databases → Create → Couchbase** and link it
to your app's environment, the platform injects these variables automatically:

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
