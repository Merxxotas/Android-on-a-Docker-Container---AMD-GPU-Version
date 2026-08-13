# System Recreation & Clean Setup Guide

This guide documents all necessary steps to deploy the **Android 13 (API 33)** Docker environment with **AMD GPU hardware acceleration** from scratch after a clean system reinstallation.

---

## 1. Package Installation & Host Preparation

On Ubuntu/Debian, Arch Linux, or CachyOS:

### On Debian / Ubuntu:
```bash
# 1. Install Docker, Compose, ADB, and scrcpy
sudo apt update
sudo apt install -y docker.io docker-compose-v2 adb scrcpy

# 2. Enable and start Docker daemon
sudo systemctl enable --now docker

# 3. Add your user to docker, kvm, and render groups
sudo usermod -aG docker,kvm,render $USER
```

### On CachyOS / Arch Linux:
```bash
# 1. Install packages
sudo pacman -S docker docker-compose android-tools scrcpy --noconfirm

# 2. Enable and start Docker daemon
sudo systemctl enable --now docker

# 3. Add your user to docker, kvm, and render groups
sudo usermod -aG docker,kvm,render $USER
```

> ⚠️ **Note**: Log out and log back in (or restart your machine) so group permissions (`kvm`, `render`, `docker`) take effect.

---

## 2. KVM & AMD DRI Device Verification

The Android emulator container requires direct hardware access to KVM CPU virtualization and AMD GPU Mesa DRI nodes:

```bash
ls -l /dev/kvm /dev/dri
```

### Expected Output:
- `/dev/kvm` (virtualization device)
- `/dev/dri/card1` or `/dev/dri/card0` (graphics card node)
- `/dev/dri/renderD128` (Mesa render node)

---

## 3. Project Configuration (`compose.yml` & `compose.gpu.yaml`)

The repository supports both standard KVM deployment (`compose.yml`) and GPU-accelerated deployment (`compose.gpu.yaml`):

### Standard KVM Configuration (`compose.yml`)
```yaml
services:
  android:
    build:
      context: .
      dockerfile: Dockerfile
      args:
        - API_LEVEL=33
        - CMD_LINE_VERSION=11076708_latest
        - IMG_TYPE=google_apis_playstore
        - GPU_ACCELERATED=false
    container_name: android
    environment:
      - RAM_SIZE=8G
      - DISK_SIZE=64G
      - CPU_CORES=8
      - DISABLE_ANIMATION=false
      - DISABLE_HIDDEN_POLICY=true
      - SKIP_AUTH=false
      - TZ=America/Bogota
    devices:
      - /dev/kvm:/dev/kvm
    ports:
      - "5554:5554"
      - "127.0.0.1:5555:5555"
    volumes:
      - ${ANDROID_DOCKER_ADB_HOME:-${HOME}/.local/share/android-docker/adb-home}/.android/adbkey:/root/.android/adbkey:ro
      - ${ANDROID_DOCKER_ADB_HOME:-${HOME}/.local/share/android-docker/adb-home}/.android/adbkey.pub:/root/.android/adbkey.pub:ro
      - ./data:/data
    extra_hosts:
      - "host.docker.internal:host-gateway"
    privileged: true
    tty: true
    stdin_open: true
    restart: unless-stopped
```

### GPU-Accelerated Configuration (`compose.gpu.yaml`)
```yaml
services:
  android:
    build:
      context: .
      dockerfile: Dockerfile.gpu
      args:
        - API_LEVEL=33
        - CMD_LINE_VERSION=11076708_latest
        - IMG_TYPE=google_apis_playstore
        - GPU_ACCELERATED=true
    container_name: android
    environment:
      - RAM_SIZE=8G
      - DISK_SIZE=64G
      - CPU_CORES=8
      - DISABLE_ANIMATION=false
      - DISABLE_HIDDEN_POLICY=true
      - SKIP_AUTH=false
      - TZ=America/Bogota
    devices:
      - /dev/kvm:/dev/kvm
      - /dev/dri:/dev/dri
    ports:
      - "5554:5554"
      - "127.0.0.1:5555:5555"
    volumes:
      - ${ANDROID_DOCKER_ADB_HOME:-${HOME}/.local/share/android-docker/adb-home}/.android/adbkey:/root/.android/adbkey:ro
      - ${ANDROID_DOCKER_ADB_HOME:-${HOME}/.local/share/android-docker/adb-home}/.android/adbkey.pub:/root/.android/adbkey.pub:ro
      - ./data:/data
    extra_hosts:
      - "host.docker.internal:host-gateway"
    privileged: true
    tty: true
    stdin_open: true
    restart: unless-stopped
```

---

## 4. Container Deployment & Initial Boot

1. **Navigate to project directory**:
   ```bash
   cd /home/merxx/Projects/android_Docker-version
   ```

2. **Create the external project ADB key**:
   ```bash
   ./scripts/setup-adb-key.sh
   ```

   This creates one reusable key pair under `~/.local/share/android-docker/adb-home/.android/`. It is not regenerated on each start.

3. **Build & Start Docker Container**:
   - **Standard KVM**:
     ```bash
     docker compose up -d
     ```
   - **GPU-Accelerated Passthrough**:
     ```bash
     docker compose -f compose.gpu.yaml up -d
     ```

4. **Verify ADB Connection & Boot Status**:
   ```bash
   ./scripts/project-adb.sh connect 127.0.0.1:5555
   ./scripts/project-adb.sh devices
   ./scripts/project-adb.sh -s 127.0.0.1:5555 shell getprop sys.boot_completed
   ```
   *(Returns `1` once fully booted).*

5. **Launch 60 FPS Screen Mirroring**:
   ```bash
   ./scripts/android-start.sh
   ```

6. **Run Automated Verification Tests**:
   ```bash
   ./tests/run_tests.sh
   ```

## 5. Key Rotation and AVD Recovery

If a project key is exposed, stop the container, move the existing `data/` directory to a private mode-`0700` quarantine outside the repository, generate a replacement project key, and boot a fresh AVD. Recover only the files you explicitly need from the quarantine. On physical Android devices, revoke USB debugging authorizations before approving a replacement host key.

Do not restore the old key into the repository or image. See [Security Notes](../SECURITY.md) for the complete response checklist.
