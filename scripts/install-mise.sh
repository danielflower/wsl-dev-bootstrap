#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=scripts/lib.sh
. "${ROOT_DIR}/scripts/lib.sh"

require_not_root
require_ubuntu_wsl
require_sudo

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y extrepo

if [[ ! -e /etc/apt/sources.list.d/extrepo_mise.sources && ! -e /etc/apt/sources.list.d/mise.sources ]]; then
  sudo extrepo enable mise
fi

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y mise

if ! mise_bin >/dev/null; then
  die "mise installation completed but the mise executable was not found."
fi
