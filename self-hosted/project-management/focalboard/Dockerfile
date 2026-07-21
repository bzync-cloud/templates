ARG FOCALBOARD_VERSION=latest

FROM mattermost/focalboard:${FOCALBOARD_VERSION}

USER root
COPY start.sh /start.sh
RUN chmod +x /start.sh
USER nobody

# /opt/focalboard/data holds the default SQLite database and any uploaded
# file attachments. Losing this volume on a redeploy loses that data —
# switch to a linked Postgres (MDB) instance for the database (see
# README.md) if you want that half to survive without relying on the
# platform's volume.
VOLUME ["/opt/focalboard/data"]

# The image also EXPOSEs 9092 for its internal unix-socket/local-mode
# plumbing. 8000 sorts lower, so it's still the port the platform's
# ingress and health checks target.
EXPOSE 8000

# No curl/wget in this image — use bash's /dev/tcp for a real HTTP check.
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD bash -c 'exec 3<>/dev/tcp/localhost/8000 && printf "GET / HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n" >&3 && head -1 <&3 | grep -q "200 OK"' || exit 1

ENTRYPOINT ["/start.sh"]
