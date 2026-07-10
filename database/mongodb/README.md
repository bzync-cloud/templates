# MongoDB

A deployable MongoDB template — clone, push, and Bzync Cloud builds this `Dockerfile` as-is,
same as any other template. It also matches the exact engine/version Bzync Cloud Managed
Databases (MDB) provisions in production, so it doubles as a local dev container. MDB instances
run as a single-node replica set (`--replSet`); this Dockerfile omits that since it isn't needed
outside of MDB's replication tooling.

**Supported versions:** `7.0` (default), `6.0`
**Default port:** `27017`

## Deploying

Push this directory to a repo and connect it in the Bzync Cloud dashboard like any other
template — it builds and runs as a single-container service. Set `MONGO_INITDB_DATABASE`,
`MONGO_INITDB_ROOT_USERNAME`, and `MONGO_INITDB_ROOT_PASSWORD` in the dashboard for the
environment (see `.env.example`). A deployed instance here is a plain container, not a managed
one — no automatic replication, backups, or HA. For production data, provision through
**Databases → Create → MongoDB** (MDB) instead and link it to your app's environment.

## Run locally

```bash
docker build -t bzync-mongodb-dev .
docker run -d --name mongodb-dev -p 27017:27017 --env-file .env.example bzync-mongodb-dev
```

Connect with `mongosh`:

```bash
mongosh "mongodb://app:changeme@localhost:27017/app?authSource=admin"
```

## Using MDB instead

If you provision a real managed MongoDB from **Databases → Create → MongoDB** and link it to
your app's environment, the platform injects these variables automatically:

```
DB_HOST
DB_PORT
DB_NAME
DB_USER
DB_PASSWORD
DATABASE_URL   # mongodb://user:password@host:port/dbname?authSource=admin
```

## Connecting from code

**Node (`mongodb`):**

```js
import { MongoClient } from "mongodb";
const client = new MongoClient(process.env.DATABASE_URL);
await client.connect();
```

**Python (`pymongo`):**

```python
import os
from pymongo import MongoClient
client = MongoClient(os.environ["DATABASE_URL"])
```

**Go (`mongo-driver`):**

```go
client, err := mongo.Connect(ctx, options.Client().ApplyURI(os.Getenv("DATABASE_URL")))
```
