ARG COUCHBASE_VERSION=7.6.5
FROM couchbase:${COUCHBASE_VERSION}

ENV COUCHBASE_BUCKET=app \
    COUCHBASE_USERNAME=app \
    COUCHBASE_PASSWORD=changeme

COPY entrypoint.sh /usr/local/bin/bzync-entrypoint.sh
RUN chmod +x /usr/local/bin/bzync-entrypoint.sh

EXPOSE 8091-8096 11210

ENTRYPOINT ["/usr/local/bin/bzync-entrypoint.sh"]
