#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=scripts/lib.sh
. "${ROOT_DIR}/scripts/lib.sh"

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

if ! is_interactive; then
  warn "GitHub CLI is not authenticated. Skipping login in noninteractive mode."
  warn "Run ./scripts/authenticate-github.sh later to authenticate this WSL distribution."
  exit 0
fi

cat <<'TEXT'
Create a fine-grained personal access token for this WSL instance:
https://github.com/settings/personal-access-tokens/new

Choose only the repositories you want this instance to access, and grant the
minimum repository permissions needed for Git operations and GitHub CLI use:
  - Contents: read and write
  - Metadata: read
  - Pull requests: write if you plan to create PRs from this instance
TEXT

explain_storage

token=
read -r -s -p "Paste the token you created: " token
printf '\n'

if [[ -z "$token" ]]; then
  die "No token was provided."
fi

printf '%s' "$token" | gh auth login --hostname github.com --git-protocol https --with-token
gh auth setup-git

if gh auth status --hostname github.com >/dev/null 2>&1; then
  log "GitHub authentication completed"
  credential_hint
else
  die "GitHub authentication did not complete successfully."
fi
