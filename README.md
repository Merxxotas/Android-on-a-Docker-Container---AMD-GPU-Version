# 🤖 Android 13 (API 33) Docker Setup with AMD GPU Acceleration

[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![KVM](https://img.shields.io/badge/KVM-Accelerated-FF6600?style=for-the-badge&logo=linux&logoColor=white)](https://www.linux-kvm.org/)
[![AMD Radeon](https://img.shields.io/badge/AMD%20GPU-Mesa%20DRI-ED1C24?style=for-the-badge&logo=amd&logoColor=white)](https://www.amd.com/)
[![Android 13](https://img.shields.io/badge/Android-API%2033%20%7C%20Play%20Store-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://www.android.com/)
[![scrcpy](https://img.shields.io/badge/scrcpy-60%20FPS-000000?style=for-the-badge&logo=android&logoColor=white)](https://github.com/Genymobile/scrcpy)
[![CI/CD Pipeline](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?style=for-the-badge&logo=githubactions&logoColor=white)](.github/workflows/ci.yml)
[![CI/CD & Automated Testing Pipeline](https://github.com/Merxxotas/Android-on-a-Docker-Container---AMD-GPU-Version/actions/workflows/ci.yml/badge.svg)](https://github.com/Merxxotas/Android-on-a-Docker-Container---AMD-GPU-Version/actions/workflows/ci.yml)

An optimized environment to run an **Android 13 (API 33)** emulator with **Google Play Store** inside a KVM + AMD GPU DRI accelerated Docker container, featuring smooth **60 FPS** screen mirroring with **scrcpy**, 8 CPU cores, and an automated CI/CD test suite.

---

## ✨ Key Features

- ⚡ **Near-Native Performance**: KVM CPU virtualization + AMD Mesa DRI GPU hardware acceleration (`/dev/dri` & `/dev/kvm`).
- 🏎️ **8 CPU Cores & 8 GB RAM**: High-performance multi-threaded specs (`CPU_CORES=8`, `RAM_SIZE=8G`).
- 🏬 **Google Play Store Built-in**: Full support for installing and running Google Play apps.
- 📱 **Real-time Mirroring with `scrcpy`**: Smooth 60 FPS graphical interface mirroring over H.264 ADB video stream.
- 🔄 **Automated CI/CD & Testing**: GitHub Actions workflow and automated validation suite (`tests/run_tests.sh`).
- 📁 **Organized Structure**: Upstream repo preserved in `upstream/`, detailed documentation in `docs/`.

---

## 📁 Repository Structure

```text
.
├── compose.yml                 # Root Docker Compose configuration (AMD DRI, 8 Cores, 8G RAM, 64G Disk)
├── Dockerfile                  # Customized Dockerfile with Mesa DRI drivers & JDK 17
├── README.md                   # Main project README & quick reference
├── .github/
│   └── workflows/
│       └── ci.yml              # GitHub Actions CI/CD & automated testing pipeline
├── docs/
│   ├── SYSTEM_RECREATION.md    # Clean setup & reinstallation guide from scratch
│   └── USER_MANUAL.md          # Complete user manual (scrcpy, ADB commands, shortcuts & specs)
├── keys/                       # Pre-seeded ADB authorization keys
│   ├── adbkey
│   └── adbkey.pub
├── scripts/
│   ├── android-start.sh        # Starts container and launches scrcpy at 60 FPS in 1 click
│   ├── android-stop.sh         # Safely stops container to free RAM & CPU
│   ├── android-status.sh       # Displays container stats, CPU/RAM usage, and ADB status
│   ├── install-sdk.sh          # Downloads Android SDK & API 33 Play Store system image
│   └── start-emulator.sh       # Container entrypoint with dynamic RAM & DISK_SIZE parsing
├── tests/
│   └── run_tests.sh            # Automated test suite (KVM, Compose syntax, ADB, Boot status)
├── data/                       # Local volume mount for persistent AVD disk storage
└── upstream/                   # Preserved original HQarroum/docker-android repository
```

---

## 🚀 Quick Start

1. **One-Click Start + 60 FPS Screen Mirroring**:
   ```bash
   chmod +x scripts/*.sh tests/*.sh
   ./scripts/android-start.sh
   ```

2. **Run Automated Test Suite**:
   ```bash
   ./tests/run_tests.sh
   ```

---

## 🛠️ Management & Testing Commands

| Action | Command | Description |
| :--- | :--- | :--- |
| **Start Emulator + 60FPS scrcpy** | `./scripts/android-start.sh` | Starts container, waits for ADB, and launches `scrcpy` at 60 FPS. |
| **Run Automated Tests** | `./tests/run_tests.sh` | Executes automated tests for KVM, ADB, OS boot, and Play Store. |
| **Stop Emulator** | `./scripts/android-stop.sh` | Safely stops container and frees RAM/CPU resources. |
| **Check Status & Specs** | `./scripts/android-status.sh` | Displays container state, memory/CPU usage, and ADB status. |

---

## 📖 Detailed Documentation

Refer to the complete technical guides in the `docs/` directory:
- [📘 System Recreation Guide](docs/SYSTEM_RECREATION.md)
- [📙 User Manual (scrcpy, ADB & Specs)](docs/USER_MANUAL.md)

---

## 📜 Acknowledgments & License

- Based on [HQarroum/docker-android](https://github.com/HQarroum/docker-android).
- Customized for AMD GPU DRI Acceleration & API 33 Play Store.
