ARG TYPESENSE_VERSION=30.1
FROM typesense/typesense:${TYPESENSE_VERSION}

# netcat-openbsd: bzync-entrypoint.sh's status sidecar needs `nc` to serve
# the HTTP response on port 3000 — wget/curl/nc aren't in the base image,
# only bash (see that script for why raw /dev/tcp alone isn't enough: bash
# can make outbound requests over /dev/tcp but can't bind/listen on a port).
RUN apt-get update && apt-get install -y --no-install-recommends netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

ENV TYPESENSE_API_KEY=changeme \
    TYPESENSE_DATA_DIR=/data \
    TYPESENSE_ENABLE_CORS=true

# Typesense's own index/snapshot files live here — losing this volume on
# a redeploy loses every collection, not just config.
VOLUME ["/data"]

COPY bzync-entrypoint.sh /usr/local/bin/bzync-entrypoint.sh
RUN chmod +x /usr/local/bin/bzync-entrypoint.sh

# 3000 declared (and lower-numbered) alongside 8108 so Bzync Cloud's
# ingress + health checks (which target the lowest-numbered EXPOSEd port —
# see compute's imageExposedPort()) hit the JSON status endpoint in
# bzync-entrypoint.sh instead of the real API's 404 on GET / (there's no
# route at "/", only under /collections, /health, etc.). Other projects on
# the internal network still connect straight to 8108 as before — EXPOSE
# doesn't affect internal container-to-container reachability, only
# ingress port selection.
EXPOSE 3000
EXPOSE 8108

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD bash -c 'exec 3<>/dev/tcp/127.0.0.1/3000 && printf "GET / HTTP/1.0\r\n\r\n" >&3 && head -1 <&3 | grep -q 200' || exit 1

# The upstream image's binary reads its config from CLI flags, not env
# vars directly (confirmed via --help) — ENTRYPOINT is reset here (instead
# of appending to the inherited one) so bzync-entrypoint.sh runs as PID 1
# and can substitute $TYPESENSE_* itself before execing the real binary.
ENTRYPOINT ["/usr/local/bin/bzync-entrypoint.sh"]
