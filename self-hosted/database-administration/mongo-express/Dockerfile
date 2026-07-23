ARG MONGO_EXPRESS_VERSION=1.0.2

FROM mongo-express:${MONGO_EXPRESS_VERSION}

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 8081

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD curl -fsS http://localhost:8081/status || exit 1

# Keep tini as PID 1 (signal forwarding, zombie reaping) exactly like the
# upstream image's own entrypoint, just routed through our wrapper first.
ENTRYPOINT ["/sbin/tini", "--", "/start.sh"]
CMD ["mongo-express"]
