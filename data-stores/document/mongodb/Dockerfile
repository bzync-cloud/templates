ARG MONGO_VERSION=7.0
FROM mongo:${MONGO_VERSION}

ENV MONGO_INITDB_DATABASE=app \
    MONGO_INITDB_ROOT_USERNAME=app \
    MONGO_INITDB_ROOT_PASSWORD=changeme

# The base image (Ubuntu) has no netcat by default — netcat-openbsd
# provides the `nc` bzync-entrypoint.sh (and the HEALTHCHECK below) use to
# serve and probe the status endpoint.
RUN apt-get update && apt-get install -y --no-install-recommends netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

COPY bzync-entrypoint.sh /usr/local/bin/bzync-entrypoint.sh
RUN chmod +x /usr/local/bin/bzync-entrypoint.sh

# 3000 declared (and lower-numbered) alongside 27017 so Bzync Cloud's
# ingress + health checks (which target the lowest-numbered EXPOSEd port —
# see compute's imageExposedPort()) hit the HTTP status endpoint in
# bzync-entrypoint.sh instead of raw MongoDB's own protocol on 27017.
# Other projects on the internal network still connect straight to 27017
# as before — EXPOSE doesn't affect internal container-to-container
# reachability, only ingress port selection.
EXPOSE 3000
EXPOSE 27017

# nc, not wget/curl — the base image ships neither.
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD sh -c "printf 'GET / HTTP/1.0\r\n\r\n' | nc -w 2 127.0.0.1 3000 | grep -q '\"status\":\"ok\"'" || exit 1

ENTRYPOINT ["/usr/local/bin/bzync-entrypoint.sh"]
