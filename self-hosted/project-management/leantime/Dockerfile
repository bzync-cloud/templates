ARG LEANTIME_VERSION=latest

FROM leantime/leantime:${LEANTIME_VERSION}

# /var/www/html/userfiles holds uploaded attachments (avatars, ticket
# files, project documents) — losing this volume on a redeploy loses that
# data. All other application data lives in the linked MySQL/MariaDB
# database, not in the container.
VOLUME ["/var/www/html/userfiles"]

# The image also EXPOSEs 9000 for PHP-FPM (fronted internally by the
# nginx on 8080, not meant to be reached directly). 8080 sorts lower, so
# it's still the port the platform's ingress and health checks target.
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -fsS http://localhost:8080/ || exit 1
