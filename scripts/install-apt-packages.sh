#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=scripts/lib.sh
. "${ROOT_DIR}/scripts/lib.sh"

require_not_root
require_ubuntu_wsl
require_sudo

packages=(
  apt-transport-https
  bash-completion
  build-essential
  ca-certificates
  curl
  file
  git
  gnupg
  jq
  less
  lsb-release
  openssh-client
  procps
  ripgrep
  rsync
  shellcheck
  software-properties-common
  tar
  tree
  unzip
  xz-utils
  zip
)

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${packages[@]}"
