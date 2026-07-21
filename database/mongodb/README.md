# MongoDB

A deployable MongoDB template — clone, push, and Bzync Cloud builds this `Dockerfile` as-is,
same as any other template. It matches the exact engine/version Bzync Cloud's production Managed
Databases (MDB) provisions — but this tier has no managed database service of its own (mdb was
removed here; see the workspace root `README.md`), so it doubles as a local dev container rather
than a stand-in for a real managed instance. Production MDB instances run as a single-node
replica set (`--replSet`); this Dockerfile omits that since it isn't needed outside of MDB's own
replication tooling.

**Supported versions:** `7.0` (default), `6.0`
**Default port:** `27017`

## Deploying

Push this directory to a repo and connect it in the Bzync Cloud dashboard like any other
template — it builds and runs as a single-container service. Set `MONGO_INITDB_DATABASE`,
`MONGO_INITDB_ROOT_USERNAME`, and `MONGO_INITDB_ROOT_PASSWORD` in the dashboard for the
environment (see `.env.example`). A deployed instance here is a plain container, not a managed
one — no automatic replication, backups, or HA, and no managed alternative to fall back to on
this tier: this deployment *is* the database for any app here that needs MongoDB.

## Run locally

```bash
docker build -t bzync-mongodb-dev .
docker run -d --name mongodb-dev -p 27017:27017 --env-file .env.example bzync-mongodb-dev
```

Connect with `mongosh`:

```bash
mongosh "mongodb://app:changeme@localhost:27017/app?authSource=admin"
```

## Connecting another app to this database

There's no dashboard "link" step on this tier — deploy this template as its own app, then set
matching connection env vars on whichever app needs to reach it (its internal address, plus the
`MONGO_INITDB_DATABASE`/`MONGO_INITDB_ROOT_USERNAME`/`MONGO_INITDB_ROOT_PASSWORD` you set
above):

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
