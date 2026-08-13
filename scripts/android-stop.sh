#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

echo "Stopping Android Emulator container..."
docker compose down

echo "Disconnecting project ADB..."
"$SCRIPT_DIR/project-adb.sh" disconnect 127.0.0.1:5555 2>/dev/null || true
"$SCRIPT_DIR/project-adb.sh" kill-server 2>/dev/null || true

echo "Android Emulator container stopped."
