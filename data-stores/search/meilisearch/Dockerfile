ARG MEILISEARCH_VERSION=latest
FROM getmeili/meilisearch:${MEILISEARCH_VERSION}

# MEILI_MASTER_KEY is deliberately not set here — same reasoning as
# ZITADEL_MASTERKEY/GITLAB_ROOT_PASSWORD elsewhere in this repo. Meilisearch
# requires at least 16 bytes in production mode; the repo-standard
# "changeme" placeholder (8 bytes) fails outright at startup instead of
# just warning (confirmed by testing). Set a real one in .env.example.
ENV MEILI_ENV=production \
    MEILI_NO_ANALYTICS=true

# Meilisearch's own index/task-database files live here — losing this
# volume on a redeploy loses every index, not just config.
VOLUME ["/meili_data"]

COPY bzync-entrypoint.sh /usr/local/bin/bzync-entrypoint.sh
RUN chmod +x /usr/local/bin/bzync-entrypoint.sh

# 3000 declared (and lower-numbered) alongside 7700 so Bzync Cloud's
# ingress + health checks (which target the lowest-numbered EXPOSEd port —
# see compute's imageExposedPort()) hit the JSON status endpoint in
# bzync-entrypoint.sh — added for consistency with the redis/garage/
# seaweedfs/typesense templates, even though Meilisearch's real port
# already answers GET / with a native 200 JSON status (see that script).
# Other projects on the internal network still connect straight to 7700
# as before — EXPOSE doesn't affect internal container-to-container
# reachability, only ingress port selection.
EXPOSE 3000
EXPOSE 7700

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/ 2>/dev/null | grep -q '"status":"ok"' || exit 1

ENTRYPOINT ["/usr/local/bin/bzync-entrypoint.sh"]
