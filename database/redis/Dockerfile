ARG REDIS_VERSION=7.2-alpine
FROM redis:${REDIS_VERSION}

ENV REDIS_PASSWORD=changeme

EXPOSE 6379

CMD ["sh", "-c", "redis-server --requirepass \"$REDIS_PASSWORD\" --appendonly yes"]
