#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib.sh
. "${ROOT_DIR}/scripts/lib.sh"

main() {
  require_not_root
  require_ubuntu_wsl
  require_sudo

  log "Installing base apt packages"
  "${ROOT_DIR}/scripts/install-apt-packages.sh"

  log "Installing GitHub CLI"
  "${ROOT_DIR}/scripts/install-github-cli.sh"

  log "Installing mise"
  "${ROOT_DIR}/scripts/install-mise.sh"

  log "Configuring Bash activation"
  "${ROOT_DIR}/scripts/configure-shell.sh"

  log "Configuring Git safe defaults"
  "${ROOT_DIR}/scripts/configure-git.sh"

  log "Installing mise-managed tools"
  "${ROOT_DIR}/scripts/install-tools.sh"

  log "Checking GitHub authentication"
  "${ROOT_DIR}/scripts/authenticate-github.sh"

  log "Running verification"
  "${ROOT_DIR}/verify.sh"

  log "Bootstrap complete. Restart your shell or run: source ~/.bashrc"
}

main "$@"
