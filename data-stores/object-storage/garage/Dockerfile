ARG GARAGE_VERSION=v2.3.0

# The upstream dxflrs/garage image is FROM scratch (just the static binary,
# no shell) — copy the binary into an alpine base instead so
# bzync-entrypoint.sh (status sidecar, rpc secret generation) has a shell,
# wget, nc, and /dev/urandom to work with.
FROM dxflrs/garage:${GARAGE_VERSION} AS garage-bin

FROM alpine:3.20
COPY --from=garage-bin /garage /garage
COPY garage.toml /etc/garage.toml

ENV GARAGE_ADMIN_TOKEN=changeme \
    GARAGE_METRICS_TOKEN=changeme \
    GARAGE_DEFAULT_ACCESS_KEY=changeme \
    GARAGE_DEFAULT_SECRET_KEY=changeme \
    GARAGE_DEFAULT_BUCKET=default

COPY bzync-entrypoint.sh /usr/local/bin/bzync-entrypoint.sh
RUN chmod +x /usr/local/bin/bzync-entrypoint.sh

# 3000 declared (and lower-numbered) alongside 3900/3903 so Bzync Cloud's
# ingress + health checks (which target the lowest-numbered EXPOSEd port —
# see compute's imageExposedPort()) hit the JSON status endpoint in
# bzync-entrypoint.sh instead of the S3 API's raw XML error on 3900. Other
# projects on the internal network still connect straight to 3900 as
# before — EXPOSE doesn't affect internal container-to-container
# reachability, only ingress port selection.
EXPOSE 3000
EXPOSE 3900
EXPOSE 3903

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/ 2>/dev/null | grep -q '"status":"ok"' || exit 1

ENTRYPOINT ["/usr/local/bin/bzync-entrypoint.sh"]
