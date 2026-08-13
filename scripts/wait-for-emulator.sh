#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ADB="$SCRIPT_DIR/project-adb.sh"
BOOT_TIMEOUT="${ANDROID_DOCKER_BOOT_TIMEOUT:-600}"
ADB_TARGET="${1:-127.0.0.1:5555}"
COMPOSE_SERVICE="${ANDROID_DOCKER_COMPOSE_SERVICE:-android}"
started_at=$(date +%s)

while true; do
  now=$(date +%s)
  elapsed=$((now - started_at))
  if (( elapsed >= BOOT_TIMEOUT )); then
    echo "Timed out waiting for authenticated Android boot after ${BOOT_TIMEOUT}s." >&2
    break
  fi

  container_id=$(docker compose ps -q "$COMPOSE_SERVICE" 2>/dev/null || true)
  if [[ -n "$container_id" ]]; then
    container_state=$(docker inspect --format '{{.State.Status}}' "$container_id" 2>/dev/null || true)
    if [[ "$container_state" == "exited" || "$container_state" == "dead" ]]; then
      echo "Android container stopped before boot (state: $container_state)." >&2
      break
    fi
  fi

  "$PROJECT_ADB" connect "$ADB_TARGET" >/dev/null 2>&1 || true
  device_state=$("$PROJECT_ADB" -s "$ADB_TARGET" get-state 2>/dev/null || true)
  if [[ "$device_state" == "device" ]]; then
    boot_status=$("$PROJECT_ADB" -s "$ADB_TARGET" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || true)
    if [[ "$boot_status" == "1" ]]; then
      echo "Android is authenticated and fully booted."
      exit 0
    fi
  fi

  sleep 5
done

echo "ADB state:"
"$PROJECT_ADB" devices -l || true
echo "Compose status:"
docker compose ps || true
echo "Container logs:"
docker compose logs --tail=120 "$COMPOSE_SERVICE" || true
exit 1
