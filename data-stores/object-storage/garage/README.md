# Garage

A deployable Garage template — clone, push, and Bzync Cloud builds this `Dockerfile` as-is, same
as any other template. Garage is an S3-compatible object store built for small, geo-distributed
self-hosted deployments; any S3 SDK/CLI works against it unchanged by pointing the endpoint at
this deployment instead of AWS. This tier has no managed database service of its own (mdb was
removed here; see the workspace root `README.md`), so this doubles as a local dev container rather
than a stand-in for a real managed instance.

**Supported version:** `v2.3.0` (default — the first release with the `--single-node` /
`--default-bucket` bootstrap flags this template relies on; see below)
**Ports:** `3000` (JSON status endpoint, EXPOSEd — see "Why a status endpoint" below), `3900` (S3
API), `3901` (RPC, internal only), `3903` (Admin API — health, metrics, cluster management)

## Single-node only

Garage is designed for multi-node, geo-replicated clusters — `replication_factor` in
`garage.toml` is pinned to `1` and the container starts with `garage server --single-node
--default-bucket`, which auto-assigns the cluster layout to itself on first boot (no manual
`garage layout assign` / `layout apply` step). There's no path to adding replica nodes on this
tier; if you need multi-node replication, run Garage yourself outside Bzync Cloud.

## Why a status endpoint

Same pattern as the `redis` and `seaweedfs` templates' `bzync-entrypoint.sh`: Garage has no web
console, and every one of its HTTP ports answers an unauthenticated `GET /` with an error, not a
`2xx`/`3xx` — the S3 API returns a 403 "AccessDenied" XML, same as MinIO's or SeaweedFS's S3
ports would. Since Bzync Cloud's ingress and health checks target the lowest-numbered `EXPOSE`d
port in the image (`imageExposedPort()` in compute), `bzync-entrypoint.sh` runs Garage alongside a
tiny sidecar HTTP server on port 3000 that live-checks Garage's own unauthenticated admin
`/health` endpoint and reports it as JSON:

```bash
curl https://your-app.app.bzync.cloud/
# {"status":"ok","service":"garage","garage":"reachable"}
```

This is what both ingress and the public dashboard URL route to. Garage's real ports (S3 API,
admin) are still reachable from other containers on the internal network regardless — `EXPOSE` is
documentation, not a firewall.

## Deploying

Push this directory to a repo and connect it in the Bzync Cloud dashboard like any other
template — it builds and runs as a single-container service. Set `GARAGE_ADMIN_TOKEN`,
`GARAGE_METRICS_TOKEN`, `GARAGE_DEFAULT_ACCESS_KEY`, and `GARAGE_DEFAULT_SECRET_KEY` in the
dashboard for the environment (see `.env.example`). Cluster RPC auth isn't configurable this way:
Garage requires it be a 32-byte hex string, which conflicts with this platform's generic
"changeme" random-secret generator (it produces base64url, not hex), so `bzync-entrypoint.sh`
generates a fresh one on every container start instead — harmless since this is single-node with
no peers ever joining. A deployed instance here is a plain container, not a managed one — no
automatic replication, backups, or HA, its data lives on the container's ephemeral disk unless you
attach a volume, and there's no managed alternative to fall back to on this tier: this deployment
*is* the object store for any app here that needs one.

## Run locally

`.env.example` ships `GARAGE_DEFAULT_SECRET_KEY=changeme` so Bzync Cloud's deploy-time seeding can
replace it with a real random secret (see `.env.example`'s header comment) — but Garage itself
requires secret keys be at least 16 characters, longer than the literal placeholder, so a bare
`docker run --env-file .env.example` (no Bzync Cloud platform involved) needs a real value
instead:

```bash
docker build -t bzync-garage-dev .
docker run -d --name garage-dev -p 3000:3000 -p 3900:3900 -p 3903:3903 \
  --env-file .env.example \
  -e GARAGE_DEFAULT_SECRET_KEY=$(openssl rand -base64 24) \
  bzync-garage-dev
```

Check cluster/bucket status with the `garage` CLI baked into the image:

```bash
docker exec garage-dev /garage -c /etc/garage.toml status
docker exec garage-dev /garage -c /etc/garage.toml bucket list
```

Or use the `mc` CLI (Garage is S3-compatible, so MinIO's client works against it too) via
path-style addressing:

```bash
mc alias set local http://127.0.0.1:3900 changeme <the secret you generated above>
mc ls local/default
```

## Connecting another app to this database

There's no dashboard "link" step on this tier — deploy this template as its own app, then set
matching connection env vars on whichever app needs to reach it (its internal address on port
`3900`, plus the `GARAGE_DEFAULT_ACCESS_KEY` / `GARAGE_DEFAULT_SECRET_KEY` you set above as the
access/secret key pair):

```
DB_HOST
DB_PORT          # 3900 — the S3 API
S3_ACCESS_KEY    # = GARAGE_DEFAULT_ACCESS_KEY
S3_SECRET_KEY    # = GARAGE_DEFAULT_SECRET_KEY
S3_BUCKET        # = GARAGE_DEFAULT_BUCKET
S3_ENDPOINT      # http://<DB_HOST>:3900
```

## Connecting from code

Any S3-compatible SDK works — set the endpoint, disable AWS's default virtual-hosted-style
bucket addressing (this template's `garage.toml` sets no `root_domain`, so Garage only answers
path-style requests), and use the default access/secret key pair.

**Node (`@aws-sdk/client-s3`):**

```js
import { S3Client } from "@aws-sdk/client-s3";
const s3 = new S3Client({
  endpoint: process.env.S3_ENDPOINT,
  forcePathStyle: true,
  credentials: {
    accessKeyId: process.env.S3_ACCESS_KEY,
    secretAccessKey: process.env.S3_SECRET_KEY,
  },
  region: "garage",
});
```

**Python (`boto3`):**

```python
import boto3, os
s3 = boto3.client(
    "s3",
    endpoint_url=os.environ["S3_ENDPOINT"],
    aws_access_key_id=os.environ["S3_ACCESS_KEY"],
    aws_secret_access_key=os.environ["S3_SECRET_KEY"],
    region_name="garage",
)
```

**Go (`aws-sdk-go-v2`):**

```go
cfg, _ := config.LoadDefaultConfig(context.TODO(),
    config.WithRegion("garage"),
    config.WithCredentialsProvider(credentials.NewStaticCredentialsProvider(
        os.Getenv("S3_ACCESS_KEY"), os.Getenv("S3_SECRET_KEY"), "")),
)
client := s3.NewFromConfig(cfg, func(o *s3.Options) {
    o.BaseEndpoint = aws.String(os.Getenv("S3_ENDPOINT"))
    o.UsePathStyle = true
})
```
