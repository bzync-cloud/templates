ARG PGADMIN_VERSION=latest

FROM dpage/pgadmin4:${PGADMIN_VERSION}

# /var/lib/pgadmin holds pgAdmin's own SQLite config DB — saved server
# connections, stored passwords, and UI preferences. Losing this volume on
# a redeploy loses that state (it does NOT lose any actual Postgres data;
# pgAdmin is a client, never a database server itself).
VOLUME ["/var/lib/pgadmin"]

# The image also EXPOSEs 443 for its optional built-in TLS mode (unused
# here — Bzync Cloud terminates TLS at the ingress). 80 sorts lower, so it's
# still the port the platform's ingress and health checks target; no
# rebuild-from-scratch trick needed like the version-control templates.
EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD wget -qO- http://localhost:80/misc/ping || exit 1
