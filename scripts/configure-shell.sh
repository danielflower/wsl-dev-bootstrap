#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=scripts/lib.sh
. "${ROOT_DIR}/scripts/lib.sh"

require_not_root

bashrc="${HOME}/.bashrc"
begin="# >>> wsl-dev-bootstrap >>>"
end="# <<< wsl-dev-bootstrap <<<"
block=$(cat <<'BASHRC_BLOCK'
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate bash)"
fi

if [[ -d "${HOME}/.local/bin" ]]; then
  case ":${PATH}:" in
    *:"${HOME}/.local/bin":*) ;;
    *) export PATH="${HOME}/.local/bin:${PATH}" ;;
  esac
fi
BASHRC_BLOCK
)

replace_managed_block "$bashrc" "$begin" "$end" "$block"
log "Updated ${bashrc} managed block"
