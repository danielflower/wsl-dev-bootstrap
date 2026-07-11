#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

# shellcheck source=scripts/lib.sh
. "${ROOT_DIR}/scripts/lib.sh"

main() {
  require_not_root
  require_ubuntu_wsl

  log "Configuring WSL settings"
  "${ROOT_DIR}/scripts/configure-wsl.sh"

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

  log "Installing global development tools"
  "${ROOT_DIR}/scripts/install-tools.sh"

  log "Running verification"
  "${ROOT_DIR}/verify.sh"

  cat <<'TEXT'
[wsl-dev-bootstrap] Base image setup complete.
[wsl-dev-bootstrap] Next:
[wsl-dev-bootstrap]   1. Exit Ubuntu.
[wsl-dev-bootstrap]   2. In PowerShell:
[wsl-dev-bootstrap]      wsl --export Ubuntu-24.04 "F:\WSL\ubuntu-24.04-base.tar"
[wsl-dev-bootstrap]      New-Item -ItemType Directory -Force F:\WSL\myproject
[wsl-dev-bootstrap]      wsl --import myproject F:\WSL\myproject "F:\WSL\ubuntu-24.04-base.tar" --version 2
[wsl-dev-bootstrap]   3. Start the project instance:
[wsl-dev-bootstrap]      wsl --distribution myproject
TEXT
}

main "$@"
