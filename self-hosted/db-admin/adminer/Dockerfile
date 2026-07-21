ARG ADMINER_VERSION=5

FROM adminer:${ADMINER_VERSION}

# Login-screen theme, read by Adminer's built-in entrypoint.sh at container
# start (symlinks designs/$ADMINER_DESIGN/adminer.css) — see .env.example.
ENV ADMINER_DESIGN=pepa-linha

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -fsS http://localhost:8080/ || exit 1
