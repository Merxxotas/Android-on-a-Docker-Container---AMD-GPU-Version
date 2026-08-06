#!/bin/bash

echo "🛑 Stopping Android Emulator container..."
docker compose down

echo "Disconnecting ADB..."
adb disconnect 127.0.0.1:5555 2>/dev/null || true

echo "✅ Android Emulator container stopped."
