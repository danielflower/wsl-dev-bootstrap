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

  log "Installing Docker"
  "${ROOT_DIR}/scripts/install-docker.sh"

  log "Installing mise"
  "${ROOT_DIR}/scripts/install-mise.sh"

  log "Configuring Bash activation"
  "${ROOT_DIR}/scripts/configure-shell.sh"

  log "Configuring Git safe defaults"
  "${ROOT_DIR}/scripts/configure-git.sh"

  log "Installing global development tools"
  "${ROOT_DIR}/scripts/install-tools.sh"

  log "Configuring Codex defaults"
  "${ROOT_DIR}/scripts/configure-codex.sh"

  log "Configuring the instance update command"
  "${ROOT_DIR}/scripts/configure-update-command.sh"

  log "Running verification"
  "${ROOT_DIR}/verify.sh"

  cat <<'TEXT'
[wsl-dev-bootstrap] Base image setup complete.
[wsl-dev-bootstrap] Next:
[wsl-dev-bootstrap]   1. Exit Ubuntu.
[wsl-dev-bootstrap]   2. Export the base image in PowerShell:
[wsl-dev-bootstrap]      $WSLDir = "F:\WSL"
[wsl-dev-bootstrap]      $BaseImage = Join-Path $WSLDir "ubuntu-24.04-base.tar"
[wsl-dev-bootstrap]      New-Item -ItemType Directory -Force $WSLDir
[wsl-dev-bootstrap]      wsl --terminate Ubuntu-24.04
[wsl-dev-bootstrap]      wsl --export Ubuntu-24.04 $BaseImage
[wsl-dev-bootstrap]   3. Create the project instance:
[wsl-dev-bootstrap]      $Project = "myproject"
[wsl-dev-bootstrap]      $ProjectDir = Join-Path $WSLDir $Project
[wsl-dev-bootstrap]      New-Item -ItemType Directory -Force $ProjectDir
[wsl-dev-bootstrap]      wsl --import $Project $ProjectDir $BaseImage --version 2
[wsl-dev-bootstrap]   4. Update the project instance:
[wsl-dev-bootstrap]      wsl --distribution $Project --exec bash -lc '~/update.sh'
[wsl-dev-bootstrap]   5. Open the project instance:
[wsl-dev-bootstrap]      wsl --distribution $Project
TEXT
}

main "$@"
