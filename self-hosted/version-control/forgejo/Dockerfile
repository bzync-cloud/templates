ARG FORGEJO_VERSION=9
FROM codeberg.org/forgejo/forgejo:${FORGEJO_VERSION} AS upstream

# Bzync Cloud routes ingress and health checks to the lowest-numbered EXPOSEd
# port of the built image (see platform-cloud-compute's imageExposedPort()).
# The upstream forgejo image bakes in EXPOSE 22 (SSH) alongside 3000 (HTTP)
# — since 22 < 3000, leaving both would silently steal ingress traffic and
# route the web UI through the SSH port instead. A plain `EXPOSE 3000` here
# can't undo that: EXPOSE declarations accumulate across layers and a child
# Dockerfile can't un-declare one it inherited. Rebuilding from `scratch`
# with `COPY --from=upstream / /` keeps the exact same filesystem but drops
# the inherited image Config (Env, Entrypoint, Cmd, ExposedPorts, ...),
# which is then redeclared explicitly below — this time with only the HTTP
# port.
FROM scratch
COPY --from=upstream / /

# Forgejo is a Gitea fork and kept its env-to-ini config system and app.ini
# layout (including the GITEA__ prefix and GITEA_CUSTOM path) for
# compatibility — this is not a typo.
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

# /data holds repos, the sqlite DB, avatars, LFS objects, Actions logs, and
# the generated app.ini (at /data/gitea/conf/app.ini, including the
# INTERNAL_TOKEN and JWT_SECRET Forgejo generates itself on first boot) —
# losing this volume on a redeploy loses the instance's actual data, not
# just its config.
VOLUME ["/data"]

# SSH is intentionally not exposed — see the FROM scratch comment above.
# Git-over-SSH still runs inside the container but isn't reachable through
# Bzync Cloud's HTTP(S)-only ingress; use HTTPS remotes instead.
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD curl -fsS http://localhost:3000/api/healthz || exit 1

WORKDIR /
ENTRYPOINT ["/usr/bin/entrypoint"]
CMD ["/bin/s6-svscan", "/etc/s6"]
