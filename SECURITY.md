# Security Notes

## ADB keys

ADB private keys are credentials. They must never be committed, copied into a Docker build context, or placed in a Docker image layer.

This project creates one project-specific key pair outside the repository on first start:

```text
~/.local/share/android-docker/adb-home/.android/adbkey
~/.local/share/android-docker/adb-home/.android/adbkey.pub
```

The private key is mode `0600`; the containing directories are mode `0700`. The key is reused on later starts. It is not rotated daily. Rotate it only if it is exposed, lost, or no longer trusted.

The `adbkey.pub` comment is public metadata. A username or hostname in that comment does not provide authentication by itself, but a published private key must be treated as compromised.

## First start

The normal workflow creates the key automatically:

```bash
./scripts/android-start.sh
```

For direct Compose usage, initialize the key first:

```bash
./scripts/setup-adb-key.sh
docker compose up -d
```

Set `ANDROID_DOCKER_ADB_HOME` to choose another private directory. Set `ANDROID_DOCKER_ADB_SERVER_PORT` to choose another local ADB server port; the default is `5038`, leaving the normal ADB server on `5037` independent.

ADB authentication is enabled. The emulator's host ADB port remains bound to `127.0.0.1`; do not publish it to a LAN address.

## If a key is exposed

1. Stop the emulator and the project ADB server.
2. Generate a replacement project key with `./scripts/setup-adb-key.sh` after moving the old project key aside.
3. Revoke USB debugging authorizations on physical Android devices that trusted the exposed host key, then approve the replacement key.
4. Recreate the emulator data volume if the exposed key was mounted or authorized there.
5. Remove the key from every Git ref and rotate any other credential that shared the same file.

Report suspected vulnerabilities privately to the repository owner before publishing details.
