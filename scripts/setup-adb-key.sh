#!/usr/bin/env bash

set -euo pipefail

ADB_HOME_DIR="${ANDROID_DOCKER_ADB_HOME:-${HOME}/.local/share/android-docker/adb-home}"
KEY_DIR="${ADB_HOME_DIR}/.android"
PRIVATE_KEY="${KEY_DIR}/adbkey"
PUBLIC_KEY="${KEY_DIR}/adbkey.pub"

mkdir -p "$KEY_DIR"
chmod 700 "$ADB_HOME_DIR" "$KEY_DIR"

if [[ -e "$PRIVATE_KEY" && ! -e "$PUBLIC_KEY" ]] || [[ ! -e "$PRIVATE_KEY" && -e "$PUBLIC_KEY" ]]; then
  echo "ADB key pair is incomplete: refusing to overwrite it." >&2
  exit 1
fi

if [[ ! -e "$PRIVATE_KEY" ]]; then
  temp_dir=$(mktemp -d "${ADB_HOME_DIR}/.keygen.XXXXXX")
  trap 'rm -rf "$temp_dir"' EXIT
  adb keygen "$temp_dir/adbkey" >/dev/null
  awk 'NF { print $1 " android-docker@local" }' "$temp_dir/adbkey.pub" > "$temp_dir/adbkey.pub.normalized"
  chmod 600 "$temp_dir/adbkey"
  chmod 644 "$temp_dir/adbkey.pub.normalized"
  mv "$temp_dir/adbkey" "$PRIVATE_KEY"
  mv "$temp_dir/adbkey.pub.normalized" "$PUBLIC_KEY"
  trap - EXIT
  rm -rf "$temp_dir"
  echo "Created project ADB key pair at $KEY_DIR"
else
  chmod 600 "$PRIVATE_KEY"
  chmod 644 "$PUBLIC_KEY"
  if ! awk 'NF >= 1 { found = 1 } END { exit(found ? 0 : 1) }' "$PUBLIC_KEY"; then
    echo "Project public key is malformed: refusing to continue." >&2
    exit 1
  fi
  normalized=$(mktemp "${ADB_HOME_DIR}/.pubkey.XXXXXX")
  awk 'NF { print $1 " android-docker@local" }' "$PUBLIC_KEY" > "$normalized"
  chmod 644 "$normalized"
  mv "$normalized" "$PUBLIC_KEY"
  echo "Using existing project ADB key pair at $KEY_DIR"
fi

