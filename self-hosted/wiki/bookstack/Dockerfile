ARG BOOKSTACK_VERSION=latest
FROM lscr.io/linuxserver/bookstack:${BOOKSTACK_VERSION}

# LinuxServer.io convention — the image's own /init (s6-overlay) runs as
# root and drops to this uid/gid for the actual app process; 1000:1000 is
# its documented default and needs no volume ownership changes to work.
ENV PUID=1000 \
    PGID=1000 \
    APP_URL=http://localhost \
    APP_KEY=changeme

# /config holds BookStack's uploaded content, page revisions cache, and
# app.php config — losing this on a redeploy loses that data (the wiki
# pages/books/chapters themselves live in MySQL/MariaDB, deployed
# separately, not here).
VOLUME ["/config"]

# 443 is also EXPOSEd by the upstream image but unused — this deployment
# shape has no TLS cert inside the container (Bzync Cloud terminates TLS
# at its own edge). 80 already sorts lower, so it's already what ingress
# and health checks target — no EXPOSE-reordering trick needed here.
EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD curl -fsS http://localhost:80/ || exit 1
