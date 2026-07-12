#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="${HOME}/wsl-dev-bootstrap"

if [[ ! -d "${ROOT_DIR}/.git" ]]; then
  printf '[wsl-dev-bootstrap] ERROR: Git checkout not found at %s\n' "${ROOT_DIR}" >&2
  exit 1
fi

cd -- "${ROOT_DIR}"
git pull --ff-only
exec ./bootstrap.sh
