#!/bin/bash

set -e

echo "🚀 Starting Android Emulator Docker container..."
docker compose up -d

echo "⏳ Waiting for ADB server port 5555 to open..."
until adb connect 127.0.0.1:5555 2>/dev/null | grep -q "connected"; do
  sleep 2
done

echo "✅ Connected to Android Emulator via ADB!"
echo "📺 Launching scrcpy screen mirror..."
scrcpy -s 127.0.0.1:5555 --max-fps=60 --video-codec=h264 --video-bit-rate=8M
