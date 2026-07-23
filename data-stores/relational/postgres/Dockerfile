ARG POSTGRES_VERSION=16
FROM postgres:${POSTGRES_VERSION}-alpine

ENV POSTGRES_DB=app \
    POSTGRES_USER=app \
    POSTGRES_PASSWORD=changeme

COPY bzync-entrypoint.sh /usr/local/bin/bzync-entrypoint.sh
RUN chmod +x /usr/local/bin/bzync-entrypoint.sh

# 3000 declared (and lower-numbered) alongside 5432 so Bzync Cloud's
# ingress + health checks (which target the lowest-numbered EXPOSEd port —
# see compute's imageExposedPort()) hit the HTTP status endpoint in
# bzync-entrypoint.sh instead of raw Postgres's own protocol on 5432. Other
# projects on the internal network still connect straight to 5432 as
# before — EXPOSE doesn't affect internal container-to-container
# reachability, only ingress port selection.
EXPOSE 3000
EXPOSE 5432

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/ 2>/dev/null | grep -q '"status":"ok"' || exit 1

ENTRYPOINT ["/usr/local/bin/bzync-entrypoint.sh"]
