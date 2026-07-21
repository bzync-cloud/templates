ARG PLANE_VERSION=stable

FROM makeplane/plane-aio-community:${PLANE_VERSION}

# The image also EXPOSEs 443 for an internal TLS option (unused here —
# Bzync Cloud terminates TLS at the ingress). 80 sorts lower, so it's still
# the port the platform's ingress and health checks target.
EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD curl -fsS http://localhost:80/ || exit 1
