ARG AUTHENTIK_VERSION=2026.5.4
FROM authentik/server:${AUTHENTIK_VERSION}

# AUTHENTIK_POSTGRESQL__* is deliberately not defaulted here (unlike
# AUTHENTIK_SECRET_KEY/AUTHENTIK_BOOTSTRAP_PASSWORD's real "changeme"
# placeholders) — authentik has no embedded/SQLite fallback, so a fake
# default like "127.0.0.1" would just fail health checks silently instead
# of making the missing dependency obvious. Set it from .env.example.
ENV AUTHENTIK_SECRET_KEY=changeme \
    AUTHENTIK_BOOTSTRAP_EMAIL=admin@your-domain.example.com \
    AUTHENTIK_BOOTSTRAP_PASSWORD=changeme \
    AUTHENTIK_ERROR_REPORTING__ENABLED=false

# The upstream image runs as uid 1000, not root — switch to root just long
# enough to install our wrapper, then switch back so authentik still runs
# as its normal unprivileged user.
USER root
COPY bzync-entrypoint.sh /usr/local/bin/bzync-entrypoint.sh
RUN chmod +x /usr/local/bin/bzync-entrypoint.sh
USER 1000

# /media (uploaded branding/icons) and /certs (imported TLS keypairs) are
# the only two directories the upstream image itself expects to persist —
# everything else (users, flows, config) lives in Postgres, deployed
# separately (see README). Losing these loses uploaded assets, not the
# instance itself.
VOLUME ["/media", "/certs"]

# No SSH/other ports baked into this image (unlike the git-hosting
# templates in this repo) — 9000 is authentik's own HTTP port and needs no
# EXPOSE-ordering trick to win ingress.
EXPOSE 9000

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=5 \
  CMD curl -fsS http://localhost:9000/-/health/live/ || exit 1

ENTRYPOINT ["/usr/local/bin/bzync-entrypoint.sh"]
