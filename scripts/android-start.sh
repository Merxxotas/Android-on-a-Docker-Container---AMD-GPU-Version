#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ADB="$SCRIPT_DIR/project-adb.sh"
WAIT_FOR_EMULATOR="$SCRIPT_DIR/wait-for-emulator.sh"

"$SCRIPT_DIR/setup-adb-key.sh"

echo "Starting Android Emulator Docker container..."
docker compose up -d

echo "Waiting for authenticated Android boot on port 5555..."
"$WAIT_FOR_EMULATOR" 127.0.0.1:5555

echo "Connected to Android Emulator via the project ADB server."
echo "Launching scrcpy screen mirror..."
ADB="$PROJECT_ADB" scrcpy -s 127.0.0.1:5555 --max-fps=60 --video-codec=h264 --video-bit-rate=8M
