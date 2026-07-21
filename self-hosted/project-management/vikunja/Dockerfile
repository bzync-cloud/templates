ARG VIKUNJA_VERSION=latest

# The upstream vikunja/vikunja image is a single static Go binary on a
# distroless-style base (no shell, no package manager) running as uid 1000.
# /db and /app/vikunja/files don't exist in that image at all, and uid 1000
# can't mkdir either of them at runtime — creating directories directly
# under "/" or "/app/vikunja" needs root. This stage pre-creates both,
# owned by 1000:1000, so they can be COPY --chown'd into the final image
# below; Docker then carries that ownership over correctly when it
# initializes the anonymous volumes declared for them.
FROM busybox:stable AS dirs
RUN mkdir -p /out/files /out/db && chown -R 1000:1000 /out/files /out/db

FROM vikunja/vikunja:${VIKUNJA_VERSION}
COPY --from=dirs --chown=1000:1000 /out/files /app/vikunja/files
COPY --from=dirs --chown=1000:1000 /out/db /db

# /db holds the default SQLite database; /app/vikunja/files holds uploaded
# task attachments. Losing either on a redeploy loses that data — switch to
# a linked Postgres (MDB) instance for the database (see README.md) if you
# want that half to survive without relying on the platform's volume.
VOLUME ["/db", "/app/vikunja/files"]

EXPOSE 3456

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD ["/app/vikunja/vikunja", "healthcheck"]
