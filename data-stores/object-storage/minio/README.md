# MinIO

A deployable MinIO template — clone, push, and Bzync Cloud builds this `Dockerfile` as-is, same
as any other template. MinIO is an S3-compatible object store: any S3 SDK/CLI works against it
unchanged by pointing the endpoint at this deployment instead of AWS. This tier has no managed
database service of its own (mdb was removed here; see the workspace root `README.md`), so this
doubles as a local dev container rather than a stand-in for a real managed instance.

**Supported version:** `RELEASE.2025-09-07T16-13-09Z` (default — MinIO's upstream `minio/minio`
image was archived after this release; there is no newer official tag to track)
**Ports:** `9000` (S3 API), `9001` (web console) — see "Why only the console is EXPOSEd" below

## Why only the console is EXPOSEd

MinIO answers HTTP on both ports, but an unauthenticated `GET /` against the S3 API (`9000`)
returns a `403` XML error, not a `2xx`/`3xx` — Bzync Cloud's ingress and health checks target the
lowest-numbered `EXPOSE`d port in the image (see `imageExposedPort()` in compute), and a `403`
there would leave the public dashboard URL permanently unhealthy. The console's login page answers
`200` on `/` instead, so only `9001` is declared, and that's what ingress and the dashboard URL
route to:

```bash
curl -I https://your-app.app.bzync.cloud/
# HTTP/1.1 200 OK  (MinIO console login page)
```

This has no effect on the S3 API's reachability — Docker's `EXPOSE` is documentation, not a
firewall. Other apps on the internal network still reach the API directly at `9000` (see
"Connecting another app to this database" below); `9001` is purely for the public URL, the
browser console, and health checks (`/minio/health/live` on `9000`, checked from inside the
container regardless of what's `EXPOSE`d).

## Deploying

Push this directory to a repo and connect it in the Bzync Cloud dashboard like any other
template — it builds and runs as a single-container service. Set `MINIO_ROOT_USER` and
`MINIO_ROOT_PASSWORD` in the dashboard for the environment (see `.env.example`;
`MINIO_ROOT_PASSWORD` must be at least 8 characters, which MinIO enforces at startup). A deployed
instance here is a plain container, not a managed one — no automatic replication, backups, or HA,
its data lives on the container's ephemeral disk unless you attach a volume, and there's no
managed alternative to fall back to on this tier: this deployment *is* the object store for any
app here that needs one.

## Run locally

```bash
docker build -t bzync-minio-dev .
docker run -d --name minio-dev -p 9000:9000 -p 9001:9001 --env-file .env.example bzync-minio-dev
```

Open the console at `http://127.0.0.1:9001` and log in with `MINIO_ROOT_USER` /
`MINIO_ROOT_PASSWORD`, or use the `mc` CLI:

```bash
mc alias set local http://127.0.0.1:9000 admin changeme
mc mb local/my-bucket
```

## Connecting another app to this database

There's no dashboard "link" step on this tier — deploy this template as its own app, then set
matching connection env vars on whichever app needs to reach it (its internal address on port
`9000`, plus the `MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD` you set above as the access/secret key
pair):

```
DB_HOST
DB_PORT          # 9000 — the S3 API, not 9001
S3_ACCESS_KEY    # = MINIO_ROOT_USER
S3_SECRET_KEY    # = MINIO_ROOT_PASSWORD
S3_ENDPOINT      # http://<DB_HOST>:9000
```

## Connecting from code

Any S3-compatible SDK works — set the endpoint, disable AWS's default virtual-hosted-style
bucket addressing (MinIO expects path-style), and use the root user/password as the key pair.

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

**Go (`minio-go`):**

```go
client, err := minio.New(os.Getenv("DB_HOST")+":9000", &minio.Options{
    Creds: credentials.NewStaticV4(os.Getenv("S3_ACCESS_KEY"), os.Getenv("S3_SECRET_KEY"), ""),
})
```
