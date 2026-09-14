#!/bin/sh
set -eu

: "${RELEASE_IMAGE:?RELEASE_IMAGE is required}"

CONTAINER_NAME="${CONTAINER_NAME:-d3h1-privacy}"
CANDIDATE_NAME="${CANDIDATE_NAME:-${CONTAINER_NAME}-candidate}"
HOST_PORT="${HOST_PORT:-2007}"
ALT_PORT="${ALT_PORT:-2017}"
NGINX_SERVICE="${NGINX_SERVICE:-${CONTAINER_NAME}}"
UPSTREAM_FILE="${UPSTREAM_FILE:-/etc/nginx/upstream/${NGINX_SERVICE}.conf}"
SWITCH_COMMAND="${SWITCH_COMMAND:-sudo -n /usr/local/sbin/nginx-switch-upstream}"
CONTAINER_PORT="${CONTAINER_PORT:-3000}"
HEALTH_ATTEMPTS="${HEALTH_ATTEMPTS:-30}"
HEALTH_INTERVAL="${HEALTH_INTERVAL:-2}"
# reload 직후에도 이전 워커가 남아 기존 연결을 처리한다.
# 이 시간만큼 기다린 뒤 이전 컨테이너를 제거한다.
DRAIN_SECONDS="${DRAIN_SECONDS:-10}"

if [ "$HOST_PORT" = "$ALT_PORT" ]; then
  printf 'HOST_PORT and ALT_PORT must differ: %s\n' "$HOST_PORT" >&2
  exit 1
fi


if [ -n "${APP_ENV_FILE:-}" ] && [ ! -r "$APP_ENV_FILE" ]; then
  printf 'Environment file is not readable: %s\n' "$APP_ENV_FILE" >&2
  exit 1
fi

wait_for_health() {
  container="$1"
  attempt=1

  while [ "$attempt" -le "$HEALTH_ATTEMPTS" ]; do
    status="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}missing{{end}}' "$container" 2>/dev/null || true)"

    case "$status" in
      healthy)
        return 0
        ;;
      unhealthy|missing)
        return 1
        ;;
    esac

    sleep "$HEALTH_INTERVAL"
    attempt=$((attempt + 1))
  done

  return 1
}

run_container() {
  name="$1"
  image="$2"
  publish_port="$3"
  restart_policy="$4"

  set -- docker run --pull never -d --name "$name" --restart "$restart_policy"

  if [ -n "${APP_ENV_FILE:-}" ]; then
    set -- "$@" --env-file "$APP_ENV_FILE"
  fi

  if [ "$publish_port" != false ]; then
    set -- "$@" -p "127.0.0.1:${publish_port}:${CONTAINER_PORT}"
  fi

  set -- "$@" -e "PORT=${CONTAINER_PORT}" "$image"
  "$@" >/dev/null
}

show_logs() {
  docker logs "$1" 2>&1 || true
}

smoke_test() {
  docker rm -f "$CANDIDATE_NAME" >/dev/null 2>&1 || true
  trap 'docker rm -f "$CANDIDATE_NAME" >/dev/null 2>&1 || true' EXIT HUP INT TERM

  run_container "$CANDIDATE_NAME" "$RELEASE_IMAGE" false no

  if ! wait_for_health "$CANDIDATE_NAME"; then
    show_logs "$CANDIDATE_NAME"
    return 1
  fi

  printf 'Smoke test passed: %s\n' "$RELEASE_IMAGE"
}

container_for_port() {
  printf '%s-%s' "$CONTAINER_NAME" "$1"
}

is_running() {
  [ "$(docker inspect --format '{{.State.Running}}' "$1" 2>/dev/null || echo false)" = true ]
}

# 현재 서비스 중인 포트를 찾는다.
# upstream 파일이 실제 라우팅 대상이므로 이를 우선한다. 중단된 배포가
# 컨테이너를 남겼을 때 실행 상태만으로는 판단할 수 없기 때문이다.
active_port() {
  if [ -r "$UPSTREAM_FILE" ]; then
    port="$(sed -n 's/.*127\.0\.0\.1:\([0-9]\{1,\}\).*/\1/p' "$UPSTREAM_FILE" | head -1)"

    if [ "$port" = "$HOST_PORT" ] || [ "$port" = "$ALT_PORT" ]; then
      printf '%s' "$port"
      return 0
    fi
  fi

  if is_running "$(container_for_port "$HOST_PORT")"; then
    printf '%s' "$HOST_PORT"
  elif is_running "$(container_for_port "$ALT_PORT")"; then
    printf '%s' "$ALT_PORT"
  fi
}

switch_upstream() {
  # shellcheck disable=SC2086
  $SWITCH_COMMAND "$NGINX_SERVICE" "$1"
}

handle_deploy_exit() {
  deploy_exit_status="$?"
  trap - EXIT HUP INT TERM

  if [ "${deployment_complete:-false}" != true ] && [ -n "${target_container:-}" ]; then
    printf 'Deployment aborted; removing candidate: %s\n' "$target_container" >&2
    docker rm -f "$target_container" >/dev/null 2>&1 || true
  fi

  exit "$deploy_exit_status"
}

handle_deploy_signal() {
  printf 'Deployment interrupted\n' >&2
  trap - EXIT HUP INT TERM

  if [ -n "${target_container:-}" ]; then
    docker rm -f "$target_container" >/dev/null 2>&1 || true
  fi

  exit 1
}

deploy() {
  deployment_complete=false
  target_container=""

  trap handle_deploy_exit EXIT
  trap handle_deploy_signal HUP INT TERM

  current_port="$(active_port)"

  if [ "$current_port" = "$HOST_PORT" ]; then
    target_port="$ALT_PORT"
  else
    target_port="$HOST_PORT"
  fi

  target_container="$(container_for_port "$target_port")"

  # 이전 배포가 남긴 컨테이너가 유휴 포트를 잡고 있을 수 있다.
  docker rm -f "$target_container" >/dev/null 2>&1 || true

  printf 'Starting candidate on port %s\n' "$target_port"

  if ! run_container "$target_container" "$RELEASE_IMAGE" "$target_port" unless-stopped \
    || ! wait_for_health "$target_container"; then
    printf 'Candidate failed health check: %s\n' "$RELEASE_IMAGE" >&2
    show_logs "$target_container"
    return 1
  fi

  if ! switch_upstream "$target_port"; then
    printf 'Upstream switch failed; keeping current container\n' >&2
    return 1
  fi

  deployment_complete=true
  trap - EXIT HUP INT TERM

  if [ -n "$current_port" ]; then
    previous_container="$(container_for_port "$current_port")"

    # 이전 워커가 처리 중인 요청이 끝날 때까지 기다린다.
    # 곧바로 제거하면 아직 살아 있는 워커가 502를 반환한다.
    sleep "$DRAIN_SECONDS"

    docker rm -f "$previous_container" >/dev/null 2>&1 \
      || printf 'Warning: failed to remove previous container: %s\n' "$previous_container" >&2
  fi

  printf 'Deployment completed: %s (port %s)\n' "$RELEASE_IMAGE" "$target_port"
}

case "${1:-}" in
  smoke)
    smoke_test
    ;;
  deploy)
    deploy
    ;;
  *)
    printf 'Usage: %s {smoke|deploy}\n' "$0" >&2
    exit 2
    ;;
esac
