#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_PATH=$(readlink -f -- "${BASH_SOURCE[0]}")
ROOT_DIR=$(cd -- "$(dirname -- "${SCRIPT_PATH}")" && pwd)

cd -- "${ROOT_DIR}"
git pull --ff-only
exec ./bootstrap.sh
