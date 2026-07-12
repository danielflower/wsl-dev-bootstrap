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

if [[ $- == *i* ]]; then
  printf '\n[wsl-dev-bootstrap] Update this instance: ~/update.sh\n'
  printf '[wsl-dev-bootstrap] Authenticate GitHub: ~/wsl-dev-bootstrap/scripts/authenticate-github.sh\n'
  printf '[wsl-dev-bootstrap] Verify this instance: ~/wsl-dev-bootstrap/verify.sh\n\n'
  printf '[wsl-dev-bootstrap] Switch Java: mise shell java@temurin-17 (11, 17, 21, or 25)\n'
  printf '[wsl-dev-bootstrap] Install Playwright: npx playwright install --with-deps\n\n'
fi
BASHRC_BLOCK
)

replace_managed_block "$bashrc" "$begin" "$end" "$block"
log "Updated ${bashrc} managed block"
