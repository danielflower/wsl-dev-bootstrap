#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=scripts/lib.sh
. "${ROOT_DIR}/scripts/lib.sh"

require_not_root
require_ubuntu_wsl
require_sudo

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

{
  printf '%s\n' \
    '[boot]' \
    'systemd=true' \
    '' \
    '[user]' \
    "default=${USER}" \
    '' \
    '[automount]' \
    'enabled = false' \
    '' \
    '[interop]' \
    'enabled = false' \
    'appendWindowsPath = false'
} >"$tmp"

if [[ -e /etc/wsl.conf ]] && ! cmp -s "$tmp" /etc/wsl.conf; then
  if [[ ! -e /etc/wsl.conf.wsl-dev-bootstrap.bak ]]; then
    sudo cp -a /etc/wsl.conf /etc/wsl.conf.wsl-dev-bootstrap.bak
  fi
fi

sudo install -m 0644 "$tmp" /etc/wsl.conf
log "Configured /etc/wsl.conf for systemd, default user, and Windows isolation"
