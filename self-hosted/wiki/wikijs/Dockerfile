ARG WIKIJS_VERSION=2
FROM ghcr.io/requarks/wiki:${WIKIJS_VERSION}

ENV DB_TYPE=postgres \
    DB_PORT=5432

# Local-storage uploads and any locally-cloned content repos live here
# (the upstream image already declares this VOLUME) — everything else
# (pages, users, config) lives in Postgres, deployed separately.
VOLUME ["/wiki/data/content"]

# 3443 is also EXPOSEd by the upstream image but unused — no TLS cert
# configured inside this container in this deployment shape (Bzync Cloud
# terminates TLS at its own edge). 3000 already sorts lower, so it's
# already what ingress and health checks target — no EXPOSE-reordering
# trick needed here.
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD wget -qO- http://localhost:3000/ >/dev/null || exit 1
