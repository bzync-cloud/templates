FROM node:22-alpine
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install --omit=dev
COPY . .

# Bzync Cloud's platform-generated Dockerfile for lang=node falls through
# to its default case for framework=cron (no dedicated cron case), which
# always EXPOSEs 3000 regardless — but this template ships its own
# Dockerfile instead (see BZYNC_CLOUD), because nothing in job.js used to
# listen on any port at all, which would leave the platform's port-based
# health check dialing a port nothing answers. EXPOSE 3000 here is real:
# job.js's status HTTP server actually listens on it.
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/ 2>/dev/null | grep -q '"status":"ok"' || exit 1

CMD ["node", "job.js"]
