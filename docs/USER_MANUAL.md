# User Manual: scrcpy, ADB, Custom Hardware Specs, CI/CD & Automated Testing

Complete reference manual for using the Android 13 Docker emulator, launching 60 FPS `scrcpy` display mirroring, customizing RAM/Disk hardware specs, managing ADB key authentication, running automated test suites, and CI/CD pipelines.

---

## 1. Connecting with `scrcpy` & Screen Control

`scrcpy` provides smooth, low-latency display mirroring and keyboard/mouse interaction over ADB.

### High-Performance Connection (60 FPS + H.264):
```bash
ADB=./scripts/project-adb.sh scrcpy -s 127.0.0.1:5555 --max-fps=60 --video-codec=h264 --video-bit-rate=8M
```

### Useful `scrcpy` Shortcuts & Commands:
| Action | Key / Command | Description |
| :--- | :--- | :--- |
| **Home Button** | `Alt` + `h` / `Cmd` + `h` | Navigates to Android Home screen |
| **Back Button** | `Alt` + `b` / `Right-click` | Performs Back action |
| **App Switcher** | `Alt` + `s` | Opens Recent Apps switcher |
| **Power Button** | `Alt` + `p` | Simulates Power button |
| **Fullscreen Mode** | `Alt` + `f` | Toggles fullscreen display |
| **Paste Clipboard** | `Ctrl` + `v` | Pastes computer text directly into Android |
| **Drag & Drop APK** | Drag `.apk` into window | Installs APK file into emulator |
| **Drag & Drop File** | Drag file into window | Pushes file to `/sdcard/Download/` |

---

## 2. ADB Command Line Utilities

You can execute ADB commands directly against the containerized emulator:

```bash
# Connect ADB daemon to emulator container
./scripts/project-adb.sh connect 127.0.0.1:5555

# List connected devices
./scripts/project-adb.sh devices

# Install an APK file
./scripts/project-adb.sh -s 127.0.0.1:5555 install my-application.apk

# Access Android interactive shell
./scripts/project-adb.sh -s 127.0.0.1:5555 shell

# Inspect logcat system logs
./scripts/project-adb.sh -s 127.0.0.1:5555 logcat
```

---

## 3. Hardware Resource Customization

Hardware specs can be adjusted at any time in [`compose.yml`](file:///home/merxx/Projects/android_Docker-version/compose.yml):

```yaml
environment:
  - RAM_SIZE=8G         # Allocated RAM (e.g. 4G, 8G, 16G)
  - DISK_SIZE=64G       # Emulator data partition size (e.g. 32G, 64G, 128G)
  - CPU_CORES=8         # Assigned CPU virtual cores (Configured to 8 cores)
  - DISABLE_ANIMATION=true # Disables transition animations for max UI speed
```

To apply updated specs:
```bash
docker compose up -d
```

---

## 4. ADB Authentication Keys

For `google_apis_playstore` system images, Android requires an authenticated ADB key pair. This project keeps the project key outside the repository and uses a dedicated local ADB server on port `5038`.

- **Default project key location**:
  - `~/.local/share/android-docker/adb-home/.android/adbkey`
  - `~/.local/share/android-docker/adb-home/.android/adbkey.pub`

The normal start command creates this pair automatically. For direct Compose use, initialize it once:
```bash
./scripts/setup-adb-key.sh
docker compose up -d
```

The key is reused on later starts and is not rotated daily. Set `ANDROID_DOCKER_ADB_HOME` to use another private directory. Set `ANDROID_DOCKER_ADB_SERVER_PORT` to change the project ADB server port. Your normal ADB server on port `5037` remains separate.

Never commit these files or copy them into the Docker build context. See [Security Notes](../SECURITY.md) for incident response and migration guidance.

---

## 5. Management Scripts (`scripts/`)

Executable scripts are provided in `scripts/`:

- **Start Emulator + Auto-Connect 60 FPS `scrcpy`**:
  ```bash
  ./scripts/android-start.sh
  ```
- **Stop Emulator Container (Free RAM & CPU)**:
  ```bash
  ./scripts/android-stop.sh
  ```
- **Check Container Status & ADB Connectivity**:
  ```bash
  ./scripts/android-status.sh
  ```

---

## 6. Automated Testing & CI/CD Pipeline

The repository includes a comprehensive automated test suite and GitHub Actions workflow.

### Local Automated Test Execution:
```bash
./tests/run_tests.sh
```

**Automated Tests Verified**:
1. Docker installation & version
2. `/dev/kvm` hardware virtualization access
3. `/dev/dri` AMD graphics render node access
4. `compose.yml` configuration syntax validation
5. Authenticated ADB socket connection on `127.0.0.1:5555`
6. `sys.boot_completed` status from Android OS
7. Android API level verification (API 33)
8. Google Play Store package verification (`com.android.vending`)

### GitHub Actions Pipeline (`.github/workflows/ci.yml`):
- Triggers automatically on every `push` or `pull_request` to `main`.
- Runs ShellCheck linting, Docker build, KVM emulation boot, and automated tests.

---

## 7. Custom Dockerfile Builds & Execution

The repository includes dedicated `Dockerfile` and `Dockerfile.gpu` files that can be used via Docker Compose or directly via the Docker CLI.

### Option A: Using Docker Compose (Recommended)

- **Standard KVM Deployment (`Dockerfile`)**:
  ```bash
  docker compose build
  docker compose up -d
  ```

- **GPU-Accelerated Passthrough (`Dockerfile.gpu`)**:
  ```bash
  docker compose -f compose.gpu.yaml build
  docker compose -f compose.gpu.yaml up -d
  ```

---

### Option B: Using Direct Docker CLI (`docker build` / `docker run`)

- **Standard Build & Run (`Dockerfile`)**:
  ```bash
  # Build standard image
  docker build -t android-custom .

  # Run standard container
  docker run -d --name android \
    --device=/dev/kvm:/dev/kvm --privileged \
    -p 5554:5554 -p 127.0.0.1:5555:5555 \
    -v ${ANDROID_DOCKER_ADB_HOME:-$HOME/.local/share/android-docker/adb-home}/.android/adbkey:/root/.android/adbkey:ro \
    -v ${ANDROID_DOCKER_ADB_HOME:-$HOME/.local/share/android-docker/adb-home}/.android/adbkey.pub:/root/.android/adbkey.pub:ro \
    -v $(pwd)/data:/data \
    android-custom
  ```

- **GPU Build & Run (`Dockerfile.gpu`)**:
  ```bash
  # Build GPU-accelerated image using -f Dockerfile.gpu
  docker build -f Dockerfile.gpu -t android-gpu-custom .

  # Run GPU-accelerated container
  docker run -d --name android-gpu \
    --device=/dev/kvm:/dev/kvm --device=/dev/dri:/dev/dri --privileged \
    -p 5554:5554 -p 127.0.0.1:5555:5555 \
    -v ${ANDROID_DOCKER_ADB_HOME:-$HOME/.local/share/android-docker/adb-home}/.android/adbkey:/root/.android/adbkey:ro \
    -v ${ANDROID_DOCKER_ADB_HOME:-$HOME/.local/share/android-docker/adb-home}/.android/adbkey.pub:/root/.android/adbkey.pub:ro \
    -v $(pwd)/data:/data \
    android-gpu-custom
  ```
