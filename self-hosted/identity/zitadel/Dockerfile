ARG ZITADEL_VERSION=v4.16.1
FROM ghcr.io/zitadel/zitadel:${ZITADEL_VERSION}

# ZITADEL_FIRSTINSTANCE_ORG_HUMAN_PASSWORD is deliberately not set here —
# same reasoning as GITLAB_ROOT_PASSWORD elsewhere in this repo. ZITADEL's
# default password complexity policy requires upper+lowercase, a digit, and
# a symbol; the repo-standard "changeme" placeholder fails it outright
# (Errors.User.PasswordComplexityPolicy.HasUpper) and crashes first-boot
# setup instead of just warning, confirmed by testing both a fresh init
# with "changeme" (fails) and with the var entirely unset (succeeds — the
# org human account is created without a usable password until you set one
# — see README). Set it in .env.example to a value that actually satisfies
# the policy if you want a working password from first boot.
# ZITADEL_DATABASE_POSTGRES_*_SSL_MODE=disable matches the plain (no TLS)
# Postgres template in this catalog — there's no cert to verify against.
ENV ZITADEL_FIRSTINSTANCE_ORG_HUMAN_USERNAME=admin \
    ZITADEL_FIRSTINSTANCE_ORG_HUMAN_EMAIL_ADDRESS=admin@your-domain.example.com \
    ZITADEL_FIRSTINSTANCE_ORG_HUMAN_EMAIL_VERIFIED=true \
    ZITADEL_DATABASE_POSTGRES_USER_SSL_MODE=disable \
    ZITADEL_DATABASE_POSTGRES_ADMIN_SSL_MODE=disable \
    ZITADEL_EXTERNALSECURE=false

# Already the only EXPOSEd port in the upstream image — no EXPOSE-reordering
# trick needed here, unlike the git-hosting templates in this repo.
EXPOSE 8080

# No HEALTHCHECK here — the upstream image is fully distroless (no shell,
# no curl/wget/nc, not even `env`), so a shell-form CMD isn't an option,
# and the one candidate that survives exec form, `zitadel ready`, tested
# as permanently failing ("Error: not ready") in this deployment shape
# even while the real HTTP endpoints (/debug/healthz, /ui/console) serve
# 200 the whole time — it checks something beyond plain HTTP reachability
# that never resolves here. Bzync Cloud's own ingress health check still
# probes the container over real HTTP on port 8080 regardless of whether
# a Docker-level HEALTHCHECK is declared.
ENTRYPOINT ["/app/zitadel"]
CMD ["start-from-init", "--masterkeyFromEnv", "--tlsMode", "disabled"]
