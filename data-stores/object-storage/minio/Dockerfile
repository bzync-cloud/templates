ARG MINIO_VERSION=RELEASE.2025-09-07T16-13-09Z

# The upstream minio/minio image already bakes in `EXPOSE 9000` (the S3 API
# port) at its own layer. Docker's EXPOSE is cumulative across an image's
# entire history and can't be removed by a child Dockerfile — so adding
# `EXPOSE 9001` alone (as this Dockerfile used to) still left both 9000 and
# 9001 in the final image's ExposedPorts, and Bzync Cloud's ingress and
# health checks target the *lowest*-numbered one (imageExposedPort() in
# compute) — 9000 either way, not the console this Dockerfile intended.
# Unauthenticated GET / against 9000 (the S3 API) is a 403 XML error, not a
# 2xx/3xx, so ingress/health checks would never go healthy. Copying just
# the (statically-linked) binary into a fresh base drops that inherited
# EXPOSE entirely — same fix already used by the git-server images and the
# garage template in this catalog — so only what's declared below ends up
# in the final image.
FROM minio/minio:${MINIO_VERSION} AS minio-bin

FROM alpine:3.20
RUN apk add --no-cache ca-certificates
COPY --from=minio-bin /usr/bin/minio /usr/bin/minio

ENV MINIO_ROOT_USER=admin \
    MINIO_ROOT_PASSWORD=changeme

# Only the console is EXPOSEd — see the multi-stage comment above for why
# that's no longer undermined by an inherited port. This has no effect on
# the S3 API's reachability — EXPOSE is documentation only, not a
# firewall; other containers on the internal network still reach it
# directly at 9000 (see README).
EXPOSE 9001

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -q --spider http://localhost:9000/minio/health/live || exit 1

ENTRYPOINT ["/usr/bin/minio"]
CMD ["server", "/data", "--console-address", ":9001"]
