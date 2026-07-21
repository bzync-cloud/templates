#!/usr/bin/env sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
ONLY=${1:-}

failures=""
tested=0

log() {
  printf '%s\n' "$*"
}

template_name() {
  rel=${1#"$ROOT"/}
  printf '%s' "$rel" | tr '/.' '--'
}

image_name() {
  printf 'bzync-template-smoke:%s' "$(template_name "$1")"
}

container_name() {
  printf 'bzync-template-smoke-%s' "$(template_name "$1")"
}

network_name() {
  printf '%s-net' "$(container_name "$1")"
}

db_container_name() {
  printf '%s-db' "$(container_name "$1")"
}

env_args() {
  dir=$1
  if [ -f "$dir/.env.example" ]; then
    printf -- '--env-file %s/.env.example ' "$dir"
  fi
}

extra_env_args() {
  case ${1#"$ROOT"/} in
    php/laravel|full-stack/laravel-inertia-*)
      printf -- '-e LOG_CHANNEL=stderr -e CACHE_STORE=file -e SESSION_DRIVER=file -e QUEUE_CONNECTION=sync '
      ;;
  esac
}

extra_run_args() {
  case ${1#"$ROOT"/} in
    self-hosted/version-control/gitlab-ce)
      # GitLab's bundled Postgres and other omnibus services need more
      # shared memory than Docker's 64MB default — boot fails or degrades
      # without this, independent of how long you wait.
      printf -- '--shm-size 256m '
      ;;
  esac
}

network_args() {
  case ${1#"$ROOT"/} in
    php/joomla|python/odoo|self-hosted/db-admin/mongo-express|self-hosted/project-management/leantime|self-hosted/project-management/plane)
      printf -- '--network %s ' "$(network_name "$1")"
      ;;
  esac
}

cleanup_template() {
  dir=$1
  ctr=$(container_name "$dir")
  db=$(db_container_name "$dir")
  net=$(network_name "$dir")

  docker rm -f "$ctr" "$db" "$db-redis" "$db-rabbitmq" "$db-minio" >/dev/null 2>&1 || true
  docker network rm "$net" >/dev/null 2>&1 || true
}

start_aux_services() {
  dir=$1
  rel=${dir#"$ROOT"/}
  db=$(db_container_name "$dir")
  net=$(network_name "$dir")

  case $rel in
    php/joomla)
      docker network create "$net" >/dev/null
      docker run --rm -d --name "$db" --network "$net" --network-alias db \
        -e MARIADB_DATABASE=joomla \
        -e MARIADB_USER=joomla \
        -e MARIADB_PASSWORD=joomla \
        -e MARIADB_ROOT_PASSWORD=joomla \
        mariadb:11 >/dev/null
      ;;
    python/odoo)
      docker network create "$net" >/dev/null
      docker run --rm -d --name "$db" --network "$net" --network-alias db \
        -e POSTGRES_USER=odoo \
        -e POSTGRES_PASSWORD=odoo \
        -e POSTGRES_DB=postgres \
        postgres:16-alpine >/dev/null
      ;;
    self-hosted/db-admin/mongo-express)
      # No DB_HOST in .env.example, so the image's own baked-in default
      # (ME_CONFIG_MONGODB_URL=mongodb://mongo:27017) applies — the aux
      # container needs to be reachable at that literal hostname.
      docker network create "$net" >/dev/null
      docker run --rm -d --name "$db" --network "$net" --network-alias mongo \
        mongo:7 >/dev/null
      ;;
    self-hosted/project-management/leantime)
      # Leantime has no SQLite fallback — .env.example points LEAN_DB_HOST
      # at "db" with matching credentials, same pattern as php/joomla.
      docker network create "$net" >/dev/null
      docker run --rm -d --name "$db" --network "$net" --network-alias db \
        -e MARIADB_DATABASE=leantime \
        -e MARIADB_USER=leantime \
        -e MARIADB_PASSWORD=change-me \
        -e MARIADB_ROOT_PASSWORD=change-me \
        mariadb:11 >/dev/null
      ;;
    self-hosted/project-management/plane)
      # Plane's all-in-one image has no embedded database, cache, queue, or
      # file storage — .env.example points at "db"/"redis"/"rabbitmq"/
      # "minio" with matching credentials, all four required just to boot.
      docker network create "$net" >/dev/null
      docker run --rm -d --name "$db" --network "$net" --network-alias db \
        -e POSTGRES_USER=plane -e POSTGRES_PASSWORD=change-me -e POSTGRES_DB=plane \
        postgres:16-alpine >/dev/null
      docker run --rm -d --name "$db-redis" --network "$net" --network-alias redis \
        redis:7-alpine >/dev/null
      docker run --rm -d --name "$db-rabbitmq" --network "$net" --network-alias rabbitmq \
        -e RABBITMQ_DEFAULT_USER=plane -e RABBITMQ_DEFAULT_PASS=change-me \
        rabbitmq:3-alpine >/dev/null
      docker run --rm -d --name "$db-minio" --network "$net" --network-alias minio \
        -e MINIO_ROOT_USER=change-me -e MINIO_ROOT_PASSWORD=change-me-too \
        minio/minio server /data >/dev/null
      # The bucket .env.example's AWS_S3_BUCKET_NAME points at doesn't
      # exist until something creates it — wait for MinIO's API, then use
      # its own mc client (bundled in the server image) to make one.
      for _ in $(seq 1 30); do
        docker exec "$db-minio" mc alias set local http://localhost:9000 change-me change-me-too >/dev/null 2>&1 && break
        sleep 1
      done
      docker exec "$db-minio" mc mb local/plane >/dev/null 2>&1
      ;;
  esac
}

smoke_paths() {
  case ${1#"$ROOT"/} in
    php/laravel|full-stack/laravel-inertia-*)
      printf '/ /up'
      ;;
    self-hosted/db-admin/mongo-express)
      # / requires basic auth (401) by default — .env.example's
      # ME_CONFIG_BASICAUTH=true is intentional, see that template's
      # README. /status is the health-check route and is registered ahead
      # of the auth middleware upstream, so it alone stays reachable here.
      printf '/status'
      ;;
    *)
      printf '/'
      ;;
  esac
}

smoke_deadline() {
  case ${1#"$ROOT"/} in
    self-hosted/version-control/gitlab-ce)
      # Omnibus runs DB migrations, compiles assets, and starts ~10
      # supervised services on first boot — routinely 2-5 minutes even on
      # capable hardware, vs. seconds for every other template here.
      printf '360'
      ;;
    self-hosted/project-management/plane)
      # Waits on four aux services (Postgres, Redis, RabbitMQ, MinIO) plus
      # its own DB migrations and ~7 supervised processes on first boot.
      printf '180'
      ;;
    *)
      printf '45'
      ;;
  esac
}

wait_http() {
  base=$1
  path=$2
  deadline=$(($(date +%s) + $3))
  while [ "$(date +%s)" -lt "$deadline" ]; do
    code=$(curl -s -o /dev/null -w '%{http_code}' "$base$path" || true)
    case "$code" in
      2*|3*) return 0 ;;
      000|5*|4*) sleep 2 ;;
      *) sleep 2 ;;
    esac
  done
  return 1
}

test_dockerfile_template() {
  dir=$1
  rel=${dir#"$ROOT"/}
  img=$(image_name "$dir")
  ctr=$(container_name "$dir")

  log "==> $rel"
  cleanup_template "$dir"
  docker build -t "$img" "$dir" >/tmp/"$ctr".build.log 2>&1 || {
    cat /tmp/"$ctr".build.log
    return 1
  }

  start_aux_services "$dir" || {
    cleanup_template "$dir"
    return 1
  }

  # shellcheck disable=SC2046
  docker run --rm -d --name "$ctr" -P $(network_args "$dir") $(env_args "$dir") $(extra_env_args "$dir") $(extra_run_args "$dir") "$img" >/tmp/"$ctr".id

  port=""
  for exposed in $(docker inspect --format '{{range $p, $_ := .Config.ExposedPorts}}{{$p}} {{end}}' "$ctr"); do
    port=$(docker port "$ctr" "$exposed" 2>/dev/null | sed -n 's/.*://p' | head -1)
    [ -n "$port" ] && break
  done

  if [ -z "$port" ]; then
    docker logs "$ctr" || true
    cleanup_template "$dir"
    log "No exposed HTTP port found for $rel"
    return 1
  fi

  base="http://127.0.0.1:$port"
  deadline=$(smoke_deadline "$dir")
  for path in $(smoke_paths "$dir"); do
    if ! wait_http "$base" "$path" "$deadline"; then
      log "HTTP smoke failed for $rel at $path"
      docker logs "$ctr" || true
      cleanup_template "$dir"
      return 1
    fi
  done

  cleanup_template "$dir"
  log "ok $rel"
  return 0
}

test_static_template() {
  dir=$1
  rel=${dir#"$ROOT"/}
  log "==> $rel"
  test -f "$dir/index.html"
  log "ok $rel"
}

run_template() {
  dir=$1
  tested=$((tested + 1))
  if [ -f "$dir/Dockerfile" ]; then
    test_dockerfile_template "$dir"
  elif [ -f "$dir/index.html" ]; then
    test_static_template "$dir"
  else
    log "No testable entrypoint found for ${dir#"$ROOT"/}"
    return 1
  fi
}

if [ -n "$ONLY" ]; then
  case "$ONLY" in
    "$ROOT"/*) target=$ONLY ;;
    *) target="$ROOT/$ONLY" ;;
  esac
  if ! run_template "$target"; then
    failures="$failures ${target#"$ROOT"/}"
  fi
else
  # maxdepth 3, not 2: self-hosted/* nests one level deeper than every other
  # category (e.g. self-hosted/version-control/gitea) — bare category and
  # subcategory dirs (self-hosted, self-hosted/version-control, ...) are
  # still safe to walk over: the -f Dockerfile/index.html check below skips
  # them since none of those intermediate dirs are templates themselves.
  for dir in $(find "$ROOT" -mindepth 1 -maxdepth 3 -type d | sort); do
    case ${dir#"$ROOT"/} in
      .git|scripts|go|full-stack|node|php|python|ruby|database) continue ;;
      .git/*|scripts/*|database/*) continue ;;
    esac
    if [ -f "$dir/Dockerfile" ] || [ -f "$dir/index.html" ]; then
      if ! run_template "$dir"; then
        failures="$failures ${dir#"$ROOT"/}"
      fi
    fi
  done
fi

if [ -n "$failures" ]; then
  log ""
  log "Failed templates:$failures"
  exit 1
fi

log ""
log "All $tested template smoke tests passed."
