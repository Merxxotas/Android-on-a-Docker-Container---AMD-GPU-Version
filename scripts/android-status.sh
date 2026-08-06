#!/bin/bash

echo "=========================================="
echo "🤖 Android Container Status"
echo "=========================================="
docker compose ps

echo ""
echo "=========================================="
echo "📊 Resource Usage (CPU / RAM)"
echo "=========================================="
docker stats android --no-stream 2>/dev/null || echo "Container is not running."

echo ""
echo "=========================================="
echo "🔌 ADB Devices Status"
echo "=========================================="
adb devices
