#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=scripts/lib.sh
. "${ROOT_DIR}/scripts/lib.sh"

require_not_root
require_ubuntu_wsl
require_sudo

tmp_key=$(mktemp)
trap 'rm -f "$tmp_key"' EXIT

sudo install -d -m 0755 /etc/apt/keyrings /etc/apt/sources.list.d
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o "$tmp_key"
sudo install -m 0644 "$tmp_key" /etc/apt/keyrings/githubcli-archive-keyring.gpg

arch=$(dpkg --print-architecture)
source_line="deb [arch=${arch} signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main"
tmp_source=$(mktemp)
trap 'rm -f "$tmp_key" "$tmp_source"' EXIT
printf '%s\n' "$source_line" >"$tmp_source"
sudo install -m 0644 "$tmp_source" /etc/apt/sources.list.d/github-cli.list

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y gh
