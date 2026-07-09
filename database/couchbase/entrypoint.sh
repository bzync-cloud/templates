#!/bin/sh
# Starts couchbase-server (the base image's own entrypoint) in the background,
# then runs the same cluster-init / bucket-create / user-manage sequence that
# platform-cloud-mdb's provisioner runs against production instances, so a
# locally built container ends up in the same usable state.
set -e

/entrypoint.sh couchbase-server &
SERVER_PID=$!

until curl -sf http://localhost:8091/pools >/dev/null 2>&1; do
  sleep 2
done

couchbase-cli cluster-init \
  --cluster localhost \
  --cluster-name "$COUCHBASE_BUCKET" \
  --cluster-username "$COUCHBASE_USERNAME" \
  --cluster-password "$COUCHBASE_PASSWORD" \
  --services data,index,query \
  --cluster-ramsize 512 \
  --cluster-index-ramsize 256 || true

couchbase-cli bucket-create \
  --cluster localhost \
  --username "$COUCHBASE_USERNAME" \
  --password "$COUCHBASE_PASSWORD" \
  --bucket "$COUCHBASE_BUCKET" \
  --bucket-type couchbase \
  --bucket-ramsize 256 \
  --enable-flush 1 || true

couchbase-cli user-manage \
  --cluster localhost \
  --username "$COUCHBASE_USERNAME" \
  --password "$COUCHBASE_PASSWORD" \
  --set \
  --rbac-username "$COUCHBASE_USERNAME" \
  --rbac-password "$COUCHBASE_PASSWORD" \
  --roles "bucket_full_access[$COUCHBASE_BUCKET]" \
  --auth-domain local || true

wait "$SERVER_PID"
