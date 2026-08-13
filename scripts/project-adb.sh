#!/usr/bin/env bash

set -euo pipefail

ADB_HOME_DIR="${ANDROID_DOCKER_ADB_HOME:-${HOME}/.local/share/android-docker/adb-home}"
ADB_SERVER_PORT="${ANDROID_DOCKER_ADB_SERVER_PORT:-5038}"
KEY_FILE="${ADB_HOME_DIR}/.android/adbkey"

if [[ ! -f "$KEY_FILE" ]]; then
  "$(dirname "$0")/setup-adb-key.sh"
fi

export ADB_VENDOR_KEYS="$KEY_FILE"
exec adb -P "$ADB_SERVER_PORT" "$@"

