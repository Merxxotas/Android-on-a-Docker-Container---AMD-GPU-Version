#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ADB="$SCRIPT_DIR/project-adb.sh"

"$SCRIPT_DIR/setup-adb-key.sh"

echo "Starting Android Emulator Docker container..."
docker compose up -d

echo "Waiting for authenticated ADB on port 5555..."
until "$PROJECT_ADB" connect 127.0.0.1:5555 2>/dev/null | grep -qE "connected|already"; do
  sleep 2
done

echo "Connected to Android Emulator via the project ADB server."
echo "Launching scrcpy screen mirror..."
ADB="$PROJECT_ADB" scrcpy -s 127.0.0.1:5555 --max-fps=60 --video-codec=h264 --video-bit-rate=8M
