#!/usr/bin/env bash

log() {
  printf '[wsl-dev-bootstrap] %s\n' "$*"
}

warn() {
  printf '[wsl-dev-bootstrap] WARNING: %s\n' "$*" >&2
}

die() {
  printf '[wsl-dev-bootstrap] ERROR: %s\n' "$*" >&2
  exit 1
}

is_interactive() {
  [[ -t 0 && -t 1 ]]
}

require_not_root() {
  if [[ "${EUID}" -eq 0 ]]; then
    die "Do not run this complete bootstrap as root. Run it as your normal WSL user with sudo access."
  fi
}

require_sudo() {
  if ! command -v sudo >/dev/null 2>&1; then
    die "sudo is required. Install sudo or run from a user with sudo access."
  fi
  sudo -v
}

require_ubuntu_wsl() {
  [[ -r /etc/os-release ]] || die "Cannot read /etc/os-release. This bootstrap supports Ubuntu under WSL2."

  # shellcheck disable=SC1091
  . /etc/os-release

  [[ "${ID:-}" == "ubuntu" ]] || die "Unsupported OS '${ID:-unknown}'. This bootstrap supports Ubuntu 22.04 and 24.04 under WSL2."

  case "${VERSION_ID:-}" in
    22.04 | 24.04) ;;
    *) die "Unsupported Ubuntu version '${VERSION_ID:-unknown}'. Supported versions are 22.04 and 24.04." ;;
  esac

  if [[ ! -r /proc/sys/kernel/osrelease ]] || ! grep -qiE 'microsoft|wsl' /proc/sys/kernel/osrelease; then
    die "WSL was not detected. Run this inside an Ubuntu WSL2 distribution."
  fi
}

ensure_dir() {
  local dir=$1
  install -d -m 0755 "$dir"
}

backup_once() {
  local path=$1
  if [[ -e "$path" && ! -e "${path}.wsl-dev-bootstrap.bak" ]]; then
    cp -a "$path" "${path}.wsl-dev-bootstrap.bak"
  fi
}

replace_managed_block() {
  local file=$1
  local begin=$2
  local end=$3
  local content=$4
  local tmp

  ensure_dir "$(dirname "$file")"
  touch "$file"
  chmod 0644 "$file"
  backup_once "$file"

  tmp=$(mktemp)
  awk -v begin="$begin" -v end="$end" '
    $0 == begin { skipping = 1; next }
    $0 == end { skipping = 0; next }
    skipping != 1 { print }
  ' "$file" >"$tmp"

  {
    sed -e '${/^$/d;}' "$tmp"
    printf '\n%s\n%s\n%s\n' "$begin" "$content" "$end"
  } >"$file"

  rm -f "$tmp"
}

repo_root() {
  local source_dir
  source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
  cd -- "${source_dir}/.." && pwd
}

mise_bin() {
  if command -v mise >/dev/null 2>&1; then
    command -v mise
  elif [[ -x /usr/bin/mise ]]; then
    printf '/usr/bin/mise\n'
  elif [[ -x /usr/local/bin/mise ]]; then
    printf '/usr/local/bin/mise\n'
  elif [[ -x "${HOME}/.local/bin/mise" ]]; then
    printf '%s/.local/bin/mise\n' "$HOME"
  else
    return 1
  fi
}
