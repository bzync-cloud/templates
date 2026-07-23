ARG GITEA_VERSION=1.23
FROM gitea/gitea:${GITEA_VERSION} AS upstream

# Bzync Cloud routes ingress and health checks to the lowest-numbered EXPOSEd
# port of the built image (see platform-cloud-compute's imageExposedPort()).
# The upstream gitea/gitea image bakes in EXPOSE 22 (SSH) alongside 3000
# (HTTP) — since 22 < 3000, leaving both would silently steal ingress
# traffic and route the web UI through the SSH port instead. A plain
# `EXPOSE 3000` here can't undo that: EXPOSE declarations accumulate across
# layers and a child Dockerfile can't un-declare one it inherited. Rebuilding
# from `scratch` with `COPY --from=upstream / /` keeps the exact same
# filesystem but drops the inherited image Config (Env, Entrypoint, Cmd,
# ExposedPorts, ...), which is then redeclared explicitly below — this time
# with only the HTTP port.
FROM scratch
COPY --from=upstream / /

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    USER=git \
    GITEA_CUSTOM=/data/gitea \
    USER_UID=1000 \
    USER_GID=1000 \
    GITEA__security__INSTALL_LOCK=true \
    GITEA__security__SECRET_KEY=changeme \
    GITEA__database__DB_TYPE=sqlite3 \
    GITEA__server__HTTP_PORT=3000 \
    GITEA__server__PROTOCOL=http \
    GITEA__service__DISABLE_REGISTRATION=true \
    GITEA__service__REQUIRE_SIGNIN_VIEW=true

# Wraps the upstream entrypoint to auto-create the first admin user from
# GITEA_ADMIN_* env vars — see bzync-entrypoint.sh and the README.
COPY bzync-entrypoint.sh /usr/local/bin/bzync-entrypoint.sh
COPY bzync-create-admin.sh /usr/local/bin/bzync-create-admin.sh
RUN chmod +x /usr/local/bin/bzync-entrypoint.sh /usr/local/bin/bzync-create-admin.sh

# /data holds repos, the sqlite DB, avatars, LFS objects, and the generated
# app.ini (at /data/gitea/conf/app.ini, including the INTERNAL_TOKEN and
# JWT_SECRET Gitea generates itself on first boot) — losing this volume on a
# redeploy loses the instance's actual data, not just its config.
VOLUME ["/data"]

# SSH is intentionally not EXPOSEd here — see the FROM scratch comment
# above. That only affects Traefik's HTTP port autodetection, not SSH
# reachability: the platform's "Enable Git SSH access" project toggle binds
# a dedicated host port straight to this container's port 22 regardless of
# what's EXPOSEd. See the README's "About SSH" section.
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD curl -fsS http://localhost:3000/api/healthz || exit 1

WORKDIR /
ENTRYPOINT ["/usr/local/bin/bzync-entrypoint.sh"]
CMD ["/usr/bin/s6-svscan", "/etc/s6"]
