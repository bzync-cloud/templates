ARG SEAWEEDFS_VERSION=4.04
FROM chrislusf/seaweedfs:${SEAWEEDFS_VERSION}

ENV WEED_S3_ACCESS_KEY=admin \
    WEED_S3_SECRET_KEY=changeme

COPY bzync-entrypoint.sh /usr/local/bin/bzync-entrypoint.sh
RUN chmod +x /usr/local/bin/bzync-entrypoint.sh

# 3000 declared (and lower-numbered) alongside 8333 so Bzync Cloud's
# ingress + health checks (which target the lowest-numbered EXPOSEd port —
# see compute's imageExposedPort()) hit the JSON status endpoint in
# bzync-entrypoint.sh instead of the S3 API's raw error response on 8333.
# Other projects on the internal network still connect straight to 8333 as
# before — EXPOSE doesn't affect internal container-to-container
# reachability, only ingress port selection.
EXPOSE 3000
EXPOSE 8333

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/ 2>/dev/null | grep -q '"status":"ok"' || exit 1

ENTRYPOINT ["/usr/local/bin/bzync-entrypoint.sh"]
# `weed mini` runs master + volume + filer + S3 + WebDAV + admin UI in one
# process (unlike the plain `server` subcommand, S3 needs no separate -s3
# flag here).
CMD ["mini", "-dir=/data", "-s3.config=/etc/seaweedfs/s3.json"]
