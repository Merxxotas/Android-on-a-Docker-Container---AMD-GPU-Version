#!/bin/bash

set -e

# Sync host ADB key to ./keys/ if available on local machine
if [ -f "$HOME/.android/adbkey" ]; then
  mkdir -p ./keys
  cp "$HOME/.android/adbkey" ./keys/adbkey
  cp "$HOME/.android/adbkey.pub" ./keys/adbkey.pub
fi

echo "🚀 Starting Android Emulator Docker container..."
docker compose up -d

echo "⏳ Waiting for ADB server port 5555 to open..."
until adb connect 127.0.0.1:5555 2>/dev/null | grep -q "connected"; do
  sleep 2
done

echo "✅ Connected to Android Emulator via ADB!"
echo "📺 Launching scrcpy screen mirror..."
scrcpy -s 127.0.0.1:5555 --max-fps=60 --video-codec=h264 --video-bit-rate=8M
