#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=scripts/lib.sh
. "${ROOT_DIR}/scripts/lib.sh"

require_not_root

codex_dir="${HOME}/.codex"
codex_config="${codex_dir}/config.toml"
managed_config="${ROOT_DIR}/config/codex/config.toml"

ensure_dir "$codex_dir"
backup_once "$codex_config"
install -m 0600 "$managed_config" "$codex_config"
log "Configured Codex defaults in ${codex_config}"
