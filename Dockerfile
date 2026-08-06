FROM eclipse-temurin:17-jdk-jammy

ENV DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-c"]

# Install runtime dependencies including Mesa DRI / Vulkan GPU drivers for AMD hardware acceleration
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl sudo wget unzip bzip2 socat virt-manager htop iproute2 \
    libdrm-dev libxkbcommon-dev libgbm-dev libasound-dev libnss3 \
    libxcursor1 libpulse-dev libxshmfence-dev \
    xauth xvfb x11vnc fluxbox wmctrl libdbus-glib-1-2 \
    libgl1-mesa-dri libgl1-mesa-glx mesa-vulkan-drivers libvulkan1 \
    && rm -rf /var/lib/apt/lists/*

LABEL maintainer="Custom AMD Build"
LABEL description="Android Emulator Docker image with AMD GPU DRI Acceleration"

ARG INSTALL_ANDROID_SDK=1
ARG API_LEVEL=33
ARG IMG_TYPE=google_apis_playstore
ARG ARCHITECTURE=x86_64
ARG CMD_LINE_VERSION=11076708_latest
ARG DEVICE_ID=pixel
ARG GPU_ACCELERATED=true

ENV ANDROID_SDK_ROOT=/opt/android \
    ANDROID_PLATFORM_VERSION="platforms;android-$API_LEVEL" \
    PACKAGE_PATH="system-images;android-${API_LEVEL};${IMG_TYPE};${ARCHITECTURE}" \
    API_LEVEL=$API_LEVEL \
    DEVICE_ID=$DEVICE_ID \
    ARCHITECTURE=$ARCHITECTURE \
    ABI=${IMG_TYPE}/${ARCHITECTURE} \
    GPU_ACCELERATED=$GPU_ACCELERATED \
    QTWEBENGINE_DISABLE_SANDBOX=1 \
    ANDROID_EMULATOR_WAIT_TIME_BEFORE_KILL=10 \
    ANDROID_AVD_HOME=/data

ENV PATH="${PATH}:${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/emulator:${ANDROID_SDK_ROOT}/cmdline-tools/tools/bin"
ENV LD_LIBRARY_PATH="$ANDROID_SDK_ROOT/emulator/lib64:$ANDROID_SDK_ROOT/emulator/lib64/qt/lib"

WORKDIR /opt
EXPOSE 5554 5555

RUN mkdir -p /root/.android/ && touch /root/.android/repositories.cfg && mkdir -p /data
COPY keys/* /root/.android/

COPY scripts/install-sdk.sh /opt/
RUN chmod +x /opt/install-sdk.sh && /opt/install-sdk.sh

COPY scripts/start-emulator.sh /opt/
COPY scripts/emulator-monitoring.sh /opt/
RUN chmod +x /opt/*.sh

ENTRYPOINT ["/opt/start-emulator.sh"]