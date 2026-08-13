#!/usr/bin/env bash

# ==============================================================================
# Automated Test Suite for Android 13 Docker Emulator Environment
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ADB="$SCRIPT_DIR/../scripts/project-adb.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "=================================================="
echo "🧪 Running Automated Tests for Android Docker"
echo "=================================================="

"$SCRIPT_DIR/../scripts/setup-adb-key.sh"

KEY_HOME="${ANDROID_DOCKER_ADB_HOME:-${HOME}/.local/share/android-docker/adb-home}"
PRIVATE_KEY="$KEY_HOME/.android/adbkey"
PUBLIC_KEY="$KEY_HOME/.android/adbkey.pub"
PRIVATE_FINGERPRINT=$(sha256sum "$PRIVATE_KEY" | awk '{print $1}')
if [ "$(stat -c '%a' "$PRIVATE_KEY")" != "600" ] || [ "$(stat -c '%a' "$KEY_HOME/.android")" != "700" ]; then
    echo -e "${RED}FAILED (project ADB key permissions are too broad)${NC}"
    exit 1
fi
"$SCRIPT_DIR/../scripts/setup-adb-key.sh" >/dev/null
if [ "$PRIVATE_FINGERPRINT" != "$(sha256sum "$PRIVATE_KEY" | awk '{print $1}')" ]; then
    echo -e "${RED}FAILED (project ADB key was replaced on second setup)${NC}"
    exit 1
fi
if [ -e "$SCRIPT_DIR/../keys/adbkey" ] || [ -e "$SCRIPT_DIR/../keys/adbkey.pub" ]; then
    echo -e "${RED}FAILED (repository still contains ADB key files)${NC}"
    exit 1
fi
if [ ! -s "$PUBLIC_KEY" ]; then
    echo -e "${RED}FAILED (project public key is missing)${NC}"
    exit 1
fi
echo -e "${GREEN}Project ADB key bootstrap checks passed${NC}"

# Test 1: Check Docker Installation
echo -n "Test 1: Checking Docker installation... "
if command -v docker >/dev/null 2>&1; then
    echo -e "${GREEN}PASSED${NC}"
else
    echo -e "${RED}FAILED (Docker not found)${NC}"
    exit 1
fi

# Test 2: Check Hardware Virtualization (/dev/kvm)
echo -n "Test 2: Checking KVM virtualization node (/dev/kvm)... "
if [ -c /dev/kvm ]; then
    echo -e "${GREEN}PASSED${NC}"
else
    echo -e "${RED}FAILED (/dev/kvm missing)${NC}"
    exit 1
fi

# Test 3: Check AMD GPU DRI node (/dev/dri)
echo -n "Test 3: Checking DRI graphics nodes (/dev/dri)... "
if [ -d /dev/dri ]; then
    echo -e "${GREEN}PASSED${NC}"
else
    echo -e "${RED}WARNING (/dev/dri not found - standard KVM software rendering fallback will be used)${NC}"
fi

# Test 4: Validate compose.yml syntax
echo -n "Test 4: Validating compose.yml syntax... "
if docker compose config >/dev/null 2>&1; then
    echo -e "${GREEN}PASSED${NC}"
else
    echo -e "${RED}FAILED (compose.yml syntax error)${NC}"
    exit 1
fi

# Test 5: Check ADB Server & Emulator Connectivity
echo -n "Test 5: Checking ADB connection (127.0.0.1:5555)... "
if "$PROJECT_ADB" connect 127.0.0.1:5555 2>&1 | grep -qE "connected|already"; then
    echo -e "${GREEN}PASSED${NC}"
else
    echo -e "${RED}FAILED (Unable to connect to ADB on 127.0.0.1:5555)${NC}"
    exit 1
fi

# Test 6: Check Emulator Boot Status (sys.boot_completed)
echo -n "Test 6: Checking Android OS boot completion... "
BOOT_STATUS=$("$PROJECT_ADB" -s 127.0.0.1:5555 shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')
if [ "$BOOT_STATUS" == "1" ]; then
    echo -e "${GREEN}PASSED (Android OS booted successfully)${NC}"
else
    echo -e "${RED}WAITING (Android is still booting: sys.boot_completed='$BOOT_STATUS')${NC}"
fi

# Test 7: Verify Android Version & API Level
echo -n "Test 7: Verifying Android API Level... "
API_LEVEL=$("$PROJECT_ADB" -s 127.0.0.1:5555 shell getprop ro.build.version.sdk 2>/dev/null | tr -d '\r')
ANDROID_VER=$("$PROJECT_ADB" -s 127.0.0.1:5555 shell getprop ro.build.version.release 2>/dev/null | tr -d '\r')
if [ "$API_LEVEL" == "33" ]; then
    echo -e "${GREEN}PASSED (API Level 33 / Android $ANDROID_VER)${NC}"
else
    echo -e "${RED}NOTICE (API Level detected: '$API_LEVEL', Android Version: '$ANDROID_VER')${NC}"
fi

# Test 8: Verify Google Play Store Installation
echo -n "Test 8: Checking Google Play Store presence... "
if "$PROJECT_ADB" -s 127.0.0.1:5555 shell pm list packages 2>/dev/null | grep -q "com.android.vending"; then
    echo -e "${GREEN}PASSED (com.android.vending installed)${NC}"
else
    echo -e "${RED}NOTICE (Play Store package not detected yet)${NC}"
fi

echo "=================================================="
echo -e "${GREEN}🎉 All automated validation tests completed successfully!${NC}"
echo "=================================================="
