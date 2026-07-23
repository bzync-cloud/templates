ARG MYSQL_VERSION=8.0
FROM mysql:${MYSQL_VERSION}

ENV MYSQL_DATABASE=app \
    MYSQL_USER=app \
    MYSQL_PASSWORD=changeme \
    MYSQL_RANDOM_ROOT_PASSWORD=yes

# The base image (Oracle Linux) has no netcat — nmap-ncat provides the `nc`
# bzync-entrypoint.sh uses to serve the status endpoint below.
RUN microdnf install -y nmap-ncat && microdnf clean all

COPY bzync-entrypoint.sh /usr/local/bin/bzync-entrypoint.sh
RUN chmod +x /usr/local/bin/bzync-entrypoint.sh

# 3000 declared (and lower-numbered) alongside 3306 so Bzync Cloud's
# ingress + health checks (which target the lowest-numbered EXPOSEd port —
# see compute's imageExposedPort()) hit the HTTP status endpoint in
# bzync-entrypoint.sh instead of raw MySQL's own protocol on 3306. Other
# projects on the internal network still connect straight to 3306 as
# before — EXPOSE doesn't affect internal container-to-container
# reachability, only ingress port selection.
EXPOSE 3000
EXPOSE 3306

# curl, not wget — the base image (Oracle Linux) doesn't ship wget.
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD curl -fsS http://localhost:3000/ 2>/dev/null | grep -q '"status":"ok"' || exit 1

ENTRYPOINT ["/usr/local/bin/bzync-entrypoint.sh"]
