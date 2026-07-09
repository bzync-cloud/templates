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
  if [ -f "$dir/.env.development.example" ]; then
    printf -- '--env-file %s/.env.development.example ' "$dir"
  elif [ -f "$dir/.env.example" ]; then
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

network_args() {
  case ${1#"$ROOT"/} in
    php/joomla|python/odoo)
      printf -- '--network %s ' "$(network_name "$1")"
      ;;
  esac
}

cleanup_template() {
  dir=$1
  ctr=$(container_name "$dir")
  db=$(db_container_name "$dir")
  net=$(network_name "$dir")

  docker rm -f "$ctr" "$db" >/dev/null 2>&1 || true
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
  esac
}

smoke_paths() {
  case ${1#"$ROOT"/} in
    php/laravel|full-stack/laravel-inertia-*)
      printf '/ /up'
      ;;
    *)
      printf '/'
      ;;
  esac
}

wait_http() {
  base=$1
  path=$2
  deadline=$(($(date +%s) + 45))
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
  docker run --rm -d --name "$ctr" -P $(network_args "$dir") $(env_args "$dir") $(extra_env_args "$dir") "$img" >/tmp/"$ctr".id

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
  for path in $(smoke_paths "$dir"); do
    if ! wait_http "$base" "$path"; then
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
  for dir in $(find "$ROOT" -mindepth 1 -maxdepth 2 -type d | sort); do
    case ${dir#"$ROOT"/} in
      .git|scripts|go|full-stack|node|php|python|ruby|db) continue ;;
      .git/*|scripts/*|db/*) continue ;;
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
