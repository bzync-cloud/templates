# Meilisearch

A deployable Meilisearch template — clone, push, and Bzync Cloud builds this `Dockerfile` as-is,
same as any other template. Meilisearch is a lightweight, single-binary full-text/typo-tolerant
search engine with a REST API — no separate database or query language to learn. This tier has no
managed database service of its own (mdb was removed here; see the workspace root `README.md`),
so it doubles as a local dev container rather than a stand-in for a real managed instance.

**Supported version:** `latest` (default) — set `MEILISEARCH_VERSION` as a build arg to pin one
**Ports:** `3000` (JSON status endpoint, EXPOSEd — see "Why a status endpoint" below), `7700`
(REST API)

## Why a status endpoint

Same pattern as the `redis`/`garage`/`seaweedfs`/`typesense` templates' `bzync-entrypoint.sh`,
added here for consistency across the catalog. Meilisearch is actually the one exception where the
real API port didn't strictly need a wrapper: an unauthenticated `GET /` on `7700` already answers
`200` with `{"status":"Meilisearch is running"}` (confirmed by testing — Meilisearch's HTTP
framework returns that for any unmatched route, `/` included, rather than a `404`/`403`, unlike the
others in this catalog). `bzync-entrypoint.sh` runs `meilisearch` alongside a tiny sidecar HTTP
server on port 3000 that live-checks Meilisearch's own unauthenticated `/health` endpoint anyway,
matching the same reachable/unreachable JSON convention as the rest of the catalog:

```bash
curl https://your-app.app.bzync.cloud/
# {"status":"ok","service":"meilisearch","meilisearch":"reachable"}
```

This is what both ingress and the public dashboard URL route to. The real API is still reachable
from other containers on the internal network at `7700` regardless — `EXPOSE` is documentation,
not a firewall.

## Deploying

Push this directory to a repo and connect it in the Bzync Cloud dashboard like any other
template — it builds and runs as a single-container service. Generate a real `MEILI_MASTER_KEY`
before deploying (see `.env.example`) — unlike most secrets in this repo, this one can't use the
"changeme" placeholder-replacement convention: Meilisearch requires at least 16 bytes in
production mode and refuses to start with anything shorter. A deployed instance here is a plain
container, not a managed one — no automatic replication, backups, or HA, its index data lives on
the container's ephemeral disk unless you attach a volume, and there's no managed alternative to
fall back to on this tier: this deployment *is* the search engine for any app here that needs one.

## Run locally

```bash
docker build -t bzync-meilisearch-dev .
docker run -d --name meilisearch-dev -p 3000:3000 -p 7700:7700 \
  -e MEILI_MASTER_KEY="$(openssl rand -base64 24)" bzync-meilisearch-dev
```

Check it's up:

```bash
curl http://127.0.0.1:3000/
# {"status":"ok","service":"meilisearch","meilisearch":"reachable"}
curl http://127.0.0.1:7700/health
# {"status":"available"}
```

## Connecting another app to this database

There's no dashboard "link" step on this tier — deploy this template as its own app, then set
matching connection env vars on whichever app needs to reach it (its internal address, plus the
`MEILI_MASTER_KEY` you set above, sent as a Bearer token on every request):

```
SEARCH_HOST     # http://<internal-address>:7700
SEARCH_API_KEY  # = MEILI_MASTER_KEY
```

## Connecting from code

**Node (`meilisearch`):**

```js
import { MeiliSearch } from "meilisearch";
const client = new MeiliSearch({ host: process.env.SEARCH_HOST, apiKey: process.env.SEARCH_API_KEY });
```

**Python (`meilisearch`):**

```python
import os, meilisearch
client = meilisearch.Client(os.environ["SEARCH_HOST"], os.environ["SEARCH_API_KEY"])
```

**Go (`meilisearch-go`):**

```go
client := meilisearch.NewClient(meilisearch.ClientConfig{
    Host: os.Getenv("SEARCH_HOST"), APIKey: os.Getenv("SEARCH_API_KEY"),
})
```
