ARG MARIADB_VERSION=11
FROM mariadb:${MARIADB_VERSION}

ENV MARIADB_DATABASE=app \
    MARIADB_USER=app \
    MARIADB_PASSWORD=changeme \
    MARIADB_RANDOM_ROOT_PASSWORD=yes

# The base image (Ubuntu) has no netcat by default — netcat-openbsd
# provides the `nc` bzync-entrypoint.sh (and the HEALTHCHECK below) use to
# serve and probe the status endpoint.
RUN apt-get update && apt-get install -y --no-install-recommends netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

COPY bzync-entrypoint.sh /usr/local/bin/bzync-entrypoint.sh
RUN chmod +x /usr/local/bin/bzync-entrypoint.sh

# 3000 declared (and lower-numbered) alongside 3306 so Bzync Cloud's
# ingress + health checks (which target the lowest-numbered EXPOSEd port —
# see compute's imageExposedPort()) hit the HTTP status endpoint in
# bzync-entrypoint.sh instead of raw MariaDB's own protocol on 3306. Other
# projects on the internal network still connect straight to 3306 as
# before — EXPOSE doesn't affect internal container-to-container
# reachability, only ingress port selection.
EXPOSE 3000
EXPOSE 3306

# nc, not wget/curl — the base image ships neither.
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD sh -c "printf 'GET / HTTP/1.0\r\n\r\n' | nc -w 2 127.0.0.1 3000 | grep -q '\"status\":\"ok\"'" || exit 1

ENTRYPOINT ["/usr/local/bin/bzync-entrypoint.sh"]
