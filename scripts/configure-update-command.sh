#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

# shellcheck source=scripts/lib.sh
. "${ROOT_DIR}/scripts/lib.sh"

target="${HOME}/update.sh"

if [[ -e "${target}" && ! -L "${target}" ]]; then
  backup_once "${target}"
fi

ln -sfn "${ROOT_DIR}/update.sh" "${target}"
log "Configured ${target}"
