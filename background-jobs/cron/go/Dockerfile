FROM golang:1.24-alpine AS builder
WORKDIR /app
COPY . .
RUN go mod download && \
    CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o job .

FROM alpine:3.20
RUN apk add --no-cache ca-certificates tzdata
WORKDIR /app
COPY --from=builder /app/job .

# Bzync Cloud's platform-generated Dockerfile for lang=go always EXPOSEs
# 8080 regardless of framework (see goDockerfile() in platform/build) — but
# this template ships its own Dockerfile instead (see BZYNC_CLOUD), because
# nothing in job.go used to listen on any port at all, which would leave
# the platform's port-based health check dialing a port nothing answers.
# EXPOSE 3000 here is real: job.go's serveStatus() actually listens on it.
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/ 2>/dev/null | grep -q '"status":"ok"' || exit 1

CMD ["./job"]
