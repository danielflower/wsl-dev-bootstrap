#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=scripts/lib.sh
. "${ROOT_DIR}/scripts/lib.sh"

mode=${1:-standalone}

if ! command -v gh >/dev/null 2>&1; then
  die "GitHub CLI is not installed. Run ./scripts/install-github-cli.sh first."
fi

explain_storage() {
  cat <<'TEXT'
GitHub CLI normally stores credentials in a secure OS credential store.
If no credential store is available in this WSL distribution, gh may fall back to
a local plaintext file under its configuration directory. This script never
prints the token and never copies credentials from another WSL distribution.
TEXT
}

credential_hint() {
  local status
  status=$(gh auth status --hostname github.com 2>&1 || true)
  printf '%s\n' "$status" | sed -n '/Token:/d;/Logged in to/p;/Stored in/p;/Active account/p;/Git operations/p'
}

if gh auth status --hostname github.com >/dev/null 2>&1; then
  log "GitHub CLI is already authenticated for github.com"
  credential_hint
  exit 0
fi

if [[ "$mode" == "--offer" ]]; then
  if ! is_interactive; then
    warn "GitHub CLI is not authenticated. Skipping login in noninteractive mode."
    warn "Run ./scripts/authenticate-github.sh later to authenticate this WSL distribution."
    exit 0
  fi

  read -r -p "Authenticate GitHub CLI for this WSL distribution now? [y/N] " answer
  case "$answer" in
    [Yy] | [Yy][Ee][Ss]) ;;
    *)
      warn "Skipping GitHub authentication. Run ./scripts/authenticate-github.sh later."
      exit 0
      ;;
  esac
fi

explain_storage
gh auth login --hostname github.com --git-protocol https --web
gh auth setup-git

if gh auth status --hostname github.com >/dev/null 2>&1; then
  log "GitHub authentication completed"
  credential_hint
else
  die "GitHub authentication did not complete successfully."
fi
