# Typesense

A deployable Typesense template — clone, push, and Bzync Cloud builds this `Dockerfile` as-is,
same as any other template. Typesense is a lightweight, single-binary typo-tolerant search engine
with a REST API, similar in spirit to Meilisearch (also in this catalog's `search` category) but
with a stronger focus on faceting/filtering performance and built-in high-availability clustering
for larger deployments. This tier has no managed database service of its own (mdb was removed
here; see the workspace root `README.md`), so it doubles as a local dev container rather than a
stand-in for a real managed instance.

**Supported version:** `30.1` (default) — set `TYPESENSE_VERSION` as a build arg for others
**Ports:** `3000` (JSON status endpoint, EXPOSEd — see "Why a status endpoint" below), `8108`
(REST API)

## Why a status endpoint

Same pattern as the `redis`/`garage`/`seaweedfs` templates' `bzync-entrypoint.sh`: Typesense has
no UI, and its real API answers an unauthenticated `GET /` with a `404` ("Not Found" — there's no
route at `/`, only under `/collections`, `/health`, etc.), not a `2xx`/`3xx`. Since Bzync Cloud's
ingress and health checks target the lowest-numbered `EXPOSE`d port in the image
(`imageExposedPort()` in compute), `bzync-entrypoint.sh` runs `typesense-server` alongside a tiny
sidecar HTTP server on port 3000 that live-checks Typesense's own unauthenticated `/health`
endpoint and reports it as JSON:

```bash
curl https://your-app.app.bzync.cloud/
# {"status":"ok","service":"typesense","typesense":"reachable"}
```

This is what both ingress and the public dashboard URL route to. The real API is still reachable
from other containers on the internal network at `8108` regardless — `EXPOSE` is documentation,
not a firewall.

## Deploying

Push this directory to a repo and connect it in the Bzync Cloud dashboard like any other
template — it builds and runs as a single-container service. Set `TYPESENSE_API_KEY` in the
dashboard for the environment (see `.env.example`) — unlike Meilisearch's own template in this
catalog, Typesense doesn't enforce a minimum key length, so the repo-standard `changeme`
placeholder works fine and gets replaced with a generated random value on first deploy same as
any other secret here. A deployed instance here is a plain container, not a managed one — no
automatic replication, backups, or HA, its index data lives on the container's ephemeral disk
unless you attach a volume, and there's no managed alternative to fall back to on this tier: this
deployment *is* the search engine for any app here that needs one.

## Run locally

```bash
docker build -t bzync-typesense-dev .
docker run -d --name typesense-dev -p 3000:3000 -p 8108:8108 --env-file .env.example bzync-typesense-dev
```

Check it's up:

```bash
curl http://127.0.0.1:3000/
# {"status":"ok","service":"typesense","typesense":"reachable"}
curl http://127.0.0.1:8108/health
# {"ok":true}
```

## Connecting another app to this database

There's no dashboard "link" step on this tier — deploy this template as its own app, then set
matching connection env vars on whichever app needs to reach it (its internal address, plus the
`TYPESENSE_API_KEY` you set above):

```
SEARCH_HOST     # <internal-address>
SEARCH_PORT     # 8108
SEARCH_API_KEY  # = TYPESENSE_API_KEY
```

## Connecting from code

**Node (`typesense`):**

```js
import Typesense from "typesense";
const client = new Typesense.Client({
  nodes: [{ host: process.env.SEARCH_HOST, port: 8108, protocol: "http" }],
  apiKey: process.env.SEARCH_API_KEY,
});
```

**Python (`typesense`):**

```python
import os, typesense
client = typesense.Client({
    "nodes": [{"host": os.environ["SEARCH_HOST"], "port": "8108", "protocol": "http"}],
    "api_key": os.environ["SEARCH_API_KEY"],
})
```

**Go (`typesense-go`):**

```go
client := typesense.NewClient(
    typesense.WithServer("http://"+os.Getenv("SEARCH_HOST")+":8108"),
    typesense.WithAPIKey(os.Getenv("SEARCH_API_KEY")),
)
```
