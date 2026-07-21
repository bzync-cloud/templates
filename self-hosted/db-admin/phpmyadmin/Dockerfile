ARG PHPMYADMIN_VERSION=5.2

FROM phpmyadmin:${PHPMYADMIN_VERSION}

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -fsS http://localhost:80/ || exit 1
