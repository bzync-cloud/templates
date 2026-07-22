ARG GOGS_VERSION=0.13
FROM gogs/gogs:${GOGS_VERSION} AS upstream

# Bzync Cloud routes ingress and health checks to the lowest-numbered EXPOSEd
# port of the built image (see platform-cloud-compute's imageExposedPort()).
# The upstream gogs/gogs image bakes in EXPOSE 22 (SSH) alongside 3000
# (HTTP) — since 22 < 3000, leaving both would silently steal ingress
# traffic and route the web UI through the SSH port instead. A plain
# `EXPOSE 3000` here can't undo that: EXPOSE declarations accumulate across
# layers and a child Dockerfile can't un-declare one it inherited.
# Rebuilding from `scratch` with `COPY --from=upstream / /` keeps the exact
# same filesystem but drops the inherited image Config (Env, Cmd,
# ExposedPorts, ...), which is then redeclared explicitly below — this time
# with only the HTTP port.
FROM scratch
COPY --from=upstream / /

# gettext provides envsubst, used by entrypoint.sh to render app.ini.
RUN apk add --no-cache gettext

# PATH and GOGS_CUSTOM restore the upstream image's own environment (lost by
# rebuilding from scratch above) — Gogs shells out to `git` for repository
# operations and needs PATH to find it, even though its own launcher scripts
# use absolute paths and would otherwise boot fine without this.
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    GOGS_CUSTOM=/data/gogs \
    GOGS_APP_NAME="Gogs" \
    GOGS_DOMAIN=localhost \
    GOGS_ROOT_URL=http://localhost:3000/ \
    GOGS_HTTP_PORT=3000 \
    GOGS_SSH_PORT=22 \
    GOGS_DB_TYPE=sqlite3 \
    GOGS_DB_HOST=127.0.0.1:5432 \
    GOGS_DB_NAME=gogs \
    GOGS_DB_USER=gogs \
    GOGS_DB_PASSWORD=changeme \
    GOGS_SECRET_KEY=changeme \
    GOGS_DISABLE_REGISTRATION=true \
    GOGS_REQUIRE_SIGNIN_VIEW=true

COPY app.ini.template /etc/gogs/app.ini.template
COPY entrypoint.sh /usr/local/bin/bzync-entrypoint.sh
COPY bzync-create-admin.sh /usr/local/bin/bzync-create-admin.sh
RUN chmod +x /usr/local/bin/bzync-entrypoint.sh /usr/local/bin/bzync-create-admin.sh

# /data holds repos, the sqlite DB, and the rendered app.ini (persisted at
# /data/gogs/conf/app.ini, symlinked into place by entrypoint.sh on every
# boot) — losing this volume on a redeploy loses the instance's actual
# data, not just its config.
VOLUME ["/data"]

# SSH is intentionally not exposed — see the FROM scratch comment above.
# Gogs' own built-in SSH server is also disabled (START_SSH_SERVER=false in
# app.ini.template) in favor of the base image's real OpenSSH daemon, which
# still runs inside the container but isn't reachable through Bzync Cloud's
# HTTP(S)-only ingress; use HTTPS remotes instead.
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD wget -qO- http://localhost:3000/ >/dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/bzync-entrypoint.sh"]
