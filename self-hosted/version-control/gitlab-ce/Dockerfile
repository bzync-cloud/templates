ARG GITLAB_VERSION=17.5.2-ce.0
FROM gitlab/gitlab-ce:${GITLAB_VERSION} AS upstream

# Bzync Cloud routes ingress and health checks to the lowest-numbered EXPOSEd
# port of the built image (see platform-cloud-compute's imageExposedPort()).
# The upstream gitlab-ce image bakes in EXPOSE 22 (SSH), 80 (HTTP) and 443
# (HTTPS) — since 22 is lowest, leaving all three would silently steal
# ingress traffic and route the web UI through the SSH port instead. A plain
# `EXPOSE 80` here can't undo that: EXPOSE declarations accumulate across
# layers and a child Dockerfile can't un-declare one it inherited.
# Rebuilding from `scratch` with `COPY --from=upstream / /` keeps the exact
# same filesystem but drops the inherited image Config (Env, Cmd,
# ExposedPorts, ...), which is then redeclared explicitly below — this time
# with only the HTTP port. 443 is dropped too: there's no TLS cert
# configured inside the container in this deployment shape, so nothing
# would actually answer on it.
FROM scratch
COPY --from=upstream / /

# GITLAB_ROOT_PASSWORD is deliberately not set here. Every other template in
# this repo defaults secrets to the literal string "changeme" — Bzync
# Cloud's deploy seeding replaces that literal with a generated random value
# on first deploy (see .env.example headers throughout this repo). GitLab
# can't use that convention: it runs its own password-strength check against
# a common-password dictionary during the first-boot seed, and "changeme"
# (like most short dictionary words) fails it and crashes the reconfigure
# outright rather than just warning. Leaving the var unset is actually the
# more secure default anyway — GitLab generates its own random 32-character
# root password and writes it to /etc/gitlab/initial_root_password (see
# README.md), which beats a shared "changeme"-derived default across every
# deployment of this template even if the platform's substitution did apply.
ENV PATH=/opt/gitlab/embedded/bin:/opt/gitlab/bin:/assets:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    LANG=C.UTF-8 \
    EDITOR=/bin/vi \
    GITLAB_ALLOW_SHA1_RSA=false \
    TERM=xterm

# /etc/gitlab (config + TLS/secrets), /var/opt/gitlab (repos, the bundled
# Postgres, uploads, CI artifacts, container registry data if enabled) and
# /var/log/gitlab (service logs) are the three directories the omnibus
# package itself expects to persist — losing them loses the instance, not
# just its config. GitLab bundles its own Postgres and Redis inside the
# container (that's the point of the all-in-one "CE" image), so unlike
# gitea/forgejo/gogs there's no separate database to link for a first
# deploy.
VOLUME ["/etc/gitlab", "/var/opt/gitlab", "/var/log/gitlab"]

# SSH and HTTPS are intentionally not EXPOSEd here — see the FROM scratch
# comment above. That only affects Traefik's HTTP port autodetection, not
# SSH reachability: the platform's "Enable Git SSH access" project toggle
# binds a dedicated host port straight to this container's own SSH daemon
# regardless of what's EXPOSEd. See the README's "About SSH and HTTPS"
# section.
EXPOSE 80

# GitLab's own /-/health endpoint answers before auth and is meant exactly
# for this. start-period is generous: omnibus commonly takes several
# minutes to finish its first-boot reconfigure (migrations, asset
# compilation, ~10 supervised services) even on capable hardware — see
# README.md for realistic timing and the minimum RAM GitLab CE needs to not
# OOM-loop instead of finishing that reconfigure.
HEALTHCHECK --interval=30s --timeout=10s --start-period=600s --retries=10 \
  CMD curl -fsS http://localhost/-/health || exit 1

WORKDIR /
CMD ["/assets/wrapper"]
