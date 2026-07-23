# SeaweedFS

A deployable SeaweedFS template — clone, push, and Bzync Cloud builds this `Dockerfile` as-is,
same as any other template. SeaweedFS is an S3-compatible distributed object/file store; any S3
SDK/CLI works against it unchanged by pointing the endpoint at this deployment instead of AWS.
This tier has no managed database service of its own (mdb was removed here; see the workspace
root `README.md`), so this doubles as a local dev container rather than a stand-in for a real
managed instance.

**Supported version:** `4.04` (default)
**Ports:** `3000` (JSON status endpoint, EXPOSEd — see "Why a status endpoint" below), `8333` (S3
API), `9333` (master UI), `8888` (filer), `8080` (volume), `7333` (WebDAV), `23646` (admin UI) —
all internal-only unless EXPOSEd

## Single process, `weed mini`

The container runs `weed mini`, which bundles master, volume, filer, S3, WebDAV, and an admin UI
into one process with auto-tuned defaults — there's no separate cluster to stand up. S3
credentials are set via `WEED_S3_ACCESS_KEY` / `WEED_S3_SECRET_KEY` (see `.env.example`);
`bzync-entrypoint.sh` renders them into `/etc/seaweedfs/s3.json` before handing off to the base
image's own entrypoint, since `weed mini` has no reliable env-var equivalent for a fixed S3
credential pair (`-s3.config` pointing at a generated identity file is the dependable path).

## Why a status endpoint

Same pattern as the `redis` and `garage` templates' `bzync-entrypoint.sh`: the S3 API (`8333`)
answers an unauthenticated `GET /` with a `403`-style S3 error (it's not a UI) — SeaweedFS does
have a master admin dashboard (`9333`) that answers `200` on `GET /`, but that's an ops page for
cluster topology, not a meaningful signal that the S3 API apps actually talk to is up. Since Bzync
Cloud's ingress and health checks target the lowest-numbered `EXPOSE`d port in the image
(`imageExposedPort()` in compute), `bzync-entrypoint.sh` runs `weed mini` alongside a tiny sidecar
HTTP server on port 3000 that live-checks the master's own `/cluster/status` endpoint and reports
it as JSON:

```bash
curl https://your-app.app.bzync.cloud/
# {"status":"ok","service":"seaweedfs","seaweedfs":"reachable"}
```

This is what both ingress and the public dashboard URL route to. SeaweedFS's real ports (S3 API,
master UI, filer, etc.) are still reachable from other containers on the internal network
regardless — `EXPOSE` is documentation, not a firewall.

## Deploying

Push this directory to a repo and connect it in the Bzync Cloud dashboard like any other
template — it builds and runs as a single-container service. Set `WEED_S3_ACCESS_KEY` and
`WEED_S3_SECRET_KEY` in the dashboard for the environment (see `.env.example`). A deployed
instance here is a plain container, not a managed one — no automatic replication, backups, or HA,
its data lives on the container's ephemeral disk unless you attach a volume, and there's no
managed alternative to fall back to on this tier: this deployment *is* the object store for any
app here that needs one.

## Run locally

```bash
docker build -t bzync-seaweedfs-dev .
docker run -d --name seaweedfs-dev \
  -p 3000:3000 -p 9333:9333 -p 8333:8333 -p 8888:8888 -p 8080:8080 \
  --env-file .env.example bzync-seaweedfs-dev
```

Check the status endpoint at `http://127.0.0.1:3000`, open the master dashboard at
`http://127.0.0.1:9333`, or use the `mc` CLI (SeaweedFS's S3 gateway is compatible with MinIO's
client) via path-style addressing:

```bash
mc alias set local http://127.0.0.1:8333 admin changeme
mc mb local/my-bucket
```

## Connecting another app to this database

There's no dashboard "link" step on this tier — deploy this template as its own app, then set
matching connection env vars on whichever app needs to reach it (its internal address on port
`8333`, plus the `WEED_S3_ACCESS_KEY` / `WEED_S3_SECRET_KEY` you set above as the access/secret
key pair):

```
DB_HOST
DB_PORT          # 8333 — the S3 API, not 9333
S3_ACCESS_KEY    # = WEED_S3_ACCESS_KEY
S3_SECRET_KEY    # = WEED_S3_SECRET_KEY
S3_ENDPOINT      # http://<DB_HOST>:8333
```

## Connecting from code

Any S3-compatible SDK works — set the endpoint, disable AWS's default virtual-hosted-style bucket
addressing (SeaweedFS expects path-style), and use the access/secret key pair above.

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
  region: "us-east-1",
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
)
```

**Go (`aws-sdk-go-v2`):**

```go
cfg, _ := config.LoadDefaultConfig(context.TODO(),
    config.WithCredentialsProvider(credentials.NewStaticCredentialsProvider(
        os.Getenv("S3_ACCESS_KEY"), os.Getenv("S3_SECRET_KEY"), "")),
)
client := s3.NewFromConfig(cfg, func(o *s3.Options) {
    o.BaseEndpoint = aws.String(os.Getenv("S3_ENDPOINT"))
    o.UsePathStyle = true
})
```
