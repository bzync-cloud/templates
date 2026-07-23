ARG KEYCLOAK_VERSION=26.7
FROM keycloak/keycloak:${KEYCLOAK_VERSION}

# KC_DB is fixed at build time (Keycloak "bakes" the DB driver and enabled
# features into an optimized runtime via `kc.sh build`) — this is why
# KC_DB_URL/USERNAME/PASSWORD below are runtime-only env vars instead, set
# via .env.example, not baked here. --health-enabled turns on the
# /health/live and /health/ready endpoints on the management port (9000)
# used by HEALTHCHECK below.
RUN /opt/keycloak/bin/kc.sh build --db=postgres --health-enabled=true

# KC_BOOTSTRAP_ADMIN_* creates the first admin account on first boot
# (native to the upstream image, no wrapper script needed here) — same
# "changeme" convention as every other secret default in this repo.
# KC_HTTP_ENABLED + KC_PROXY_HEADERS let Keycloak serve plain HTTP behind
# Bzync Cloud's own TLS-terminating edge, instead of demanding a cert
# inside the container the way its production defaults otherwise require.
ENV KC_DB=postgres \
    KC_BOOTSTRAP_ADMIN_USERNAME=admin \
    KC_BOOTSTRAP_ADMIN_PASSWORD=changeme \
    KC_HTTP_ENABLED=true \
    KC_HOSTNAME_STRICT=false \
    KC_PROXY_HEADERS=xforwarded

# 8080 (HTTP) sorts lower than 8443/9000, so it's already what Bzync
# Cloud's ingress and health checks target — no EXPOSE-reordering trick
# needed here, unlike the git-hosting templates in this repo.
EXPOSE 8080
EXPOSE 9000

# No curl/wget/nc in this image (a minimal UBI-micro base, deliberately
# stripped of a package manager) — bash's /dev/tcp is what's actually
# available, so HEALTHCHECK speaks raw HTTP over it against the management
# port's /health/ready endpoint.
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=5 \
  CMD bash -c 'exec 3<>/dev/tcp/127.0.0.1/9000 && printf "GET /health/ready HTTP/1.0\r\n\r\n" >&3 && head -1 <&3 | grep -q 200' || exit 1

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
CMD ["start", "--optimized"]
