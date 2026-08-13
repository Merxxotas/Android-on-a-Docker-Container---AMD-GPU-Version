#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "Android Container Status"
echo "=========================================="
docker compose ps

echo ""
echo "=========================================="
echo "Resource Usage (CPU / RAM)"
echo "=========================================="
docker stats android --no-stream 2>/dev/null || echo "Container is not running."

echo ""
echo "=========================================="
echo "Project ADB Devices Status"
echo "=========================================="
"$SCRIPT_DIR/project-adb.sh" devices
