#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"
export COMPOSE_FILE="$PROJECT_ROOT/compose.yml:$PROJECT_ROOT/compose.integration.yaml"
PROJECT_ADB="$PROJECT_ROOT/scripts/project-adb.sh"
WAIT_FOR_EMULATOR="$PROJECT_ROOT/scripts/wait-for-emulator.sh"
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/android-docker-integration.XXXXXX")
TEST_DATA="$TEST_ROOT/data"
TEST_ADB_HOME="$TEST_ROOT/adb-home"
TEST_ADB_PORT="${ANDROID_DOCKER_TEST_ADB_SERVER_PORT:-5043}"

cleanup() {
  set +e
  ANDROID_DOCKER_ADB_HOME="$TEST_ADB_HOME" ANDROID_DOCKER_ADB_SERVER_PORT="$TEST_ADB_PORT" "$PROJECT_ADB" kill-server >/dev/null 2>&1
  ANDROID_DOCKER_ADB_HOME="$TEST_ADB_HOME" ANDROID_DOCKER_ADB_SERVER_PORT="$TEST_ADB_PORT" docker compose down --volumes --remove-orphans >/dev/null 2>&1
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

command -v docker >/dev/null
command -v adb >/dev/null
test -c /dev/kvm || { echo "KVM is unavailable; run this test on a host with /dev/kvm." >&2; exit 2; }

available_kib=$(df -Pk "$PROJECT_ROOT" | awk 'NR == 2 { print $4 }')
if (( available_kib < 80 * 1024 * 1024 )); then
  echo "At least 80 GiB of free disk is required for the disposable emulator test." >&2
  exit 2
fi

mkdir -p "$TEST_DATA"
export ANDROID_DOCKER_ADB_HOME="$TEST_ADB_HOME"
export ANDROID_DOCKER_ADB_SERVER_PORT="$TEST_ADB_PORT"
export ANDROID_DOCKER_DATA_DIR="$TEST_DATA"
export ANDROID_DOCKER_RAM_SIZE="${ANDROID_DOCKER_RAM_SIZE:-4G}"
export ANDROID_DOCKER_DISK_SIZE="${ANDROID_DOCKER_DISK_SIZE:-32G}"
export ANDROID_DOCKER_CPU_CORES="${ANDROID_DOCKER_CPU_CORES:-2}"
export ANDROID_DOCKER_BOOT_TIMEOUT="${ANDROID_DOCKER_BOOT_TIMEOUT:-600}"

"$PROJECT_ROOT/scripts/setup-adb-key.sh"
docker compose up -d --build
"$WAIT_FOR_EMULATOR" 127.0.0.1:5555

api_level=$("$PROJECT_ADB" -s 127.0.0.1:5555 shell getprop ro.build.version.sdk | tr -d '\r')
[[ "$api_level" == "33" ]] || { echo "Expected API 33, got $api_level." >&2; exit 1; }
"$PROJECT_ADB" -s 127.0.0.1:5555 shell pm list packages | grep -q 'com.android.vending'

wrong_key_dir="$TEST_ROOT/wrong-adb-home"
mkdir -p "$wrong_key_dir/.android"
adb keygen "$wrong_key_dir/.android/adbkey" >/dev/null
ANDROID_DOCKER_ADB_HOME="$wrong_key_dir" ANDROID_DOCKER_ADB_SERVER_PORT="$((TEST_ADB_PORT + 1))" "$PROJECT_ADB" connect 127.0.0.1:5555 >/dev/null 2>&1 || true
wrong_state=$(ANDROID_DOCKER_ADB_HOME="$wrong_key_dir" ANDROID_DOCKER_ADB_SERVER_PORT="$((TEST_ADB_PORT + 1))" "$PROJECT_ADB" -s 127.0.0.1:5555 get-state 2>/dev/null || true)
[[ "$wrong_state" != "device" ]] || { echo "An unrelated ADB key was accepted." >&2; exit 1; }

echo "Local Android integration test passed."
