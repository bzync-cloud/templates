FROM oven/bun:1-alpine
WORKDIR /app
COPY package.json bun.lock* bun.lockb* ./
RUN bun install
COPY . .

# The platform-generated Dockerfile for lang=bun always EXPOSEs 3000
# regardless of framework (see bunDockerfile() in platform/build) — but
# this template ships its own Dockerfile instead (see BZYNC_CLOUD),
# because nothing in worker.ts used to listen on any port at all, which
# would leave the platform's port-based health check dialing a port
# nothing answers. EXPOSE 3000 here is real: worker.ts's Bun.serve()
# actually listens on it.
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/ 2>/dev/null | grep -q '"status":"ok"' || exit 1

CMD ["bun", "worker.ts"]
