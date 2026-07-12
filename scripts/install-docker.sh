#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=scripts/lib.sh
. "${ROOT_DIR}/scripts/lib.sh"

require_not_root
require_ubuntu_wsl
require_sudo

echo "Installing Docker..."

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates curl

sudo install -m 0755 -d /etc/apt/keyrings /etc/apt/sources.list.d

tmp_key=$(mktemp)
trap 'rm -f "$tmp_key"' EXIT
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o "$tmp_key"
sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg "$tmp_key"
sudo chmod a+r /etc/apt/keyrings/docker.gpg

arch=$(dpkg --print-architecture)
# shellcheck disable=SC1091
codename=$(. /etc/os-release && echo "$VERSION_CODENAME")
source_line="deb [arch=${arch} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${codename} stable"
tmp_source=$(mktemp)
trap 'rm -f "$tmp_key" "$tmp_source"' EXIT
printf '%s\n' "$source_line" >"$tmp_source"
sudo install -m 0644 "$tmp_source" /etc/apt/sources.list.d/docker.list

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

sudo usermod -aG docker "$USER"

sudo systemctl enable docker
sudo systemctl start docker

echo
echo "Docker installed successfully."
echo
docker --version
echo
