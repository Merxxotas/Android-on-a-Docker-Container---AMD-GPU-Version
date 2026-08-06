#!/bin/bash

set -e

source ./emulator-monitoring.sh

# The emulator console port.
EMULATOR_CONSOLE_PORT=5554
# The ADB port used to connect to ADB.
ADB_PORT=5555

# Parse RAM_SIZE (e.g. 8G -> 8192) or fallback to MEMORY env
RAW_RAM=${RAM_SIZE:-${MEMORY:-8192}}
if [[ "$RAW_RAM" =~ ([0-9]+)G ]]; then
  OPT_MEMORY=$((${BASH_REMATCH[1]} * 1024))
else
  OPT_MEMORY=$RAW_RAM
fi

# Parse DISK_SIZE (e.g. 64G -> 65536) or fallback to 64G
RAW_DISK=${DISK_SIZE:-64G}
if [[ "$RAW_DISK" =~ ([0-9]+)G ]]; then
  OPT_PARTITION_SIZE=$((${BASH_REMATCH[1]} * 1024))
else
  OPT_PARTITION_SIZE=${RAW_DISK:-65536}
fi

OPT_CORES=${CPU_CORES:-${CORES:-4}}
OPT_SKIP_AUTH=${SKIP_AUTH:-true}
AUTH_FLAG=

# Start ADB server by listening on all interfaces.
echo "Starting the ADB server ..."
adb -a -P 5037 server nodaemon &

# Detect ip and forward ADB ports from the container's network
# interface to localhost.
LOCAL_IP=$(ip addr list eth0 | grep "inet " | cut -d' ' -f6 | cut -d/ -f1)
socat tcp-listen:"$EMULATOR_CONSOLE_PORT",bind="$LOCAL_IP",fork tcp:127.0.0.1:"$EMULATOR_CONSOLE_PORT" &
socat tcp-listen:"$ADB_PORT",bind="$LOCAL_IP",fork tcp:127.0.0.1:"$ADB_PORT" &

export USER=root

# Creating the Android Virtual Emulator.
TEST_AVD=$(avdmanager list avd | grep -c "android.avd" || true)
if [ "$TEST_AVD" == "1" ]; then
  echo "Use existing Android Virtual Emulator ..."
else
  echo "Creating the Android Virtual Emulator ..."
  echo "Using package '$PACKAGE_PATH', ABI '$ABI' and device '$DEVICE_ID' for creating the emulator"
  echo no | avdmanager create avd \
    --force \
    --name android \
    --abi "$ABI" \
    --package "$PACKAGE_PATH" \
    --device "$DEVICE_ID"
fi

if [ "$OPT_SKIP_AUTH" == "true" ]; then
  AUTH_FLAG="-skip-adb-auth"
fi

# If GPU acceleration is enabled, we create a virtual framebuffer
# to be used by the emulator when running with GPU acceleration.
# We also set the GPU mode to `host` to force the emulator to use
# GPU acceleration via Mesa DRI.
if [ "$GPU_ACCELERATED" == "true" ]; then
  export DISPLAY=":0.0"
  export GPU_MODE="host"
  Xvfb "$DISPLAY" -screen 0 1920x1080x16 -nolisten tcp &
else
  export GPU_MODE="swiftshader_indirect"
fi

# Asynchronously write updates on standard output about boot sequence state.
wait_for_boot &

# Start the emulator with hardware specs: RAM, CPU Cores, Partition Size.
echo "Starting the emulator ..."
echo "OPTIONS:"
echo "SKIP ADB AUTH   - $OPT_SKIP_AUTH"
echo "GPU             - $GPU_MODE"
echo "MEMORY (RAM)    - ${OPT_MEMORY}MB"
echo "DISK PARTITION  - ${OPT_PARTITION_SIZE}MB"
echo "CPU CORES       - $OPT_CORES"

emulator \
  -avd android \
  -gpu "$GPU_MODE" \
  -memory "$OPT_MEMORY" \
  -partition-size "$OPT_PARTITION_SIZE" \
  -no-boot-anim \
  -cores "$OPT_CORES" \
  -ranchu \
  $AUTH_FLAG \
  -no-window \
  -no-snapshot \
  $EXTRA_FLAGS || update_state "ANDROID_STOPPED"
