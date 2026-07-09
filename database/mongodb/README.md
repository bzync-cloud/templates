# MongoDB — Local Dev Reference

A local MongoDB container matching what Bzync Cloud Managed Databases (MDB) provisions in
production, so you can develop against the same engine version before linking the real thing.
Production instances run as a single-node replica set (`--replSet`); this Dockerfile omits
that since it isn't needed for local development against a single node.

**Supported versions:** `7.0` (default), `6.0`
**Default port:** `27017`

## Run locally

```bash
docker build -t bzync-mongodb-dev .
docker run -d --name mongodb-dev -p 27017:27017 --env-file .env.example bzync-mongodb-dev
```

Connect with `mongosh`:

```bash
mongosh "mongodb://app:changeme@localhost:27017/app?authSource=admin"
```

## Using a real managed database

This directory is a local dev stand-in — it isn't deployed by Bzync Cloud. Provision the real
thing from the dashboard: **Databases → Create → MongoDB**, then link it to your app's
environment. The platform injects these variables automatically:

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
