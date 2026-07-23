ARG SALEOR_VERSION=latest
FROM ghcr.io/saleor/saleor:${SALEOR_VERSION}

ENV SECRET_KEY=changeme \
    ALLOWED_HOSTS=* \
    DEFAULT_FROM_EMAIL=noreply@your-domain.example.com \
    DJANGO_SUPERUSER_EMAIL=admin@your-domain.example.com \
    DJANGO_SUPERUSER_PASSWORD=changeme

COPY bzync-entrypoint.sh /usr/local/bin/bzync-entrypoint.sh
RUN chmod +x /usr/local/bin/bzync-entrypoint.sh

EXPOSE 8000

# No curl/wget in this image (Python is what's actually available, and
# Saleor is a Python app anyway) — HEALTHCHECK uses a one-line urllib
# request instead of a shell HTTP client.
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=5 \
  CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://localhost:8000/graphql/',timeout=3).status<500 else 1)" || exit 1

ENTRYPOINT ["/usr/local/bin/bzync-entrypoint.sh"]
