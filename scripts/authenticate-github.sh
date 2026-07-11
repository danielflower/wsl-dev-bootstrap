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

uri_encode() {
  printf '%s' "$1" | jq -sRr @uri
}

project_label=${BOOTSTRAP_PROJECT_NAME:-${WSL_DISTRO_NAME:-wsl-dev-bootstrap}}
token_name=${BOOTSTRAP_PAT_NAME:-wsl-${project_label}}
token_description=${BOOTSTRAP_PAT_DESCRIPTION:-Access required by https://github.com/danielflower/wsl-dev-bootstrap}
token_expires_in=${BOOTSTRAP_PAT_EXPIRES_IN:-180}
token_url="https://github.com/settings/personal-access-tokens/new?name=$(uri_encode "$token_name")&description=$(uri_encode "$token_description")&expires_in=$(uri_encode "$token_expires_in")&contents=write&pull_requests=write&issues=read&actions=read&statuses=read"

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
Create a fine-grained personal access token for this WSL instance.
TEXT

printf '%s\n' "$token_url"
cat <<'TEXT'

Choose only the repositories you want this instance to access, and keep the
permissions as small as possible:
  - Contents: write
  - Pull requests: write
  - Issues: read
  - Actions: read
  - Statuses: read
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
