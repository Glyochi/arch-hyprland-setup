#!/usr/bin/env bash
set -Eeuo pipefail

CURRENT_DIR="$(pwd)"
SOURCE_ROOT_DIR="${CURRENT_DIR}"

sudo install -m 755 "${SOURCE_ROOT_DIR}/scripts/poweroff-after-suspend.sh" "/usr/lib/systemd/system-sleep/poweroff-after-suspend"
