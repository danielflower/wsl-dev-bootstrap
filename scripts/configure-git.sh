#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=scripts/lib.sh
. "${ROOT_DIR}/scripts/lib.sh"

require_not_root

managed_dir="${HOME}/.config/wsl-dev-bootstrap"
managed_gitconfig="${managed_dir}/gitconfig"
managed_gitignore="${managed_dir}/gitignore_global"

ensure_dir "$managed_dir"
install -m 0644 "${ROOT_DIR}/config/gitconfig" "$managed_gitconfig"
install -m 0644 "${ROOT_DIR}/config/gitignore_global" "$managed_gitignore"

already_included=false
while IFS= read -r include_path; do
  if [[ "$include_path" == "$managed_gitconfig" ]]; then
    already_included=true
  fi
done < <(git config --global --get-all include.path || true)

if [[ "$already_included" == false ]]; then
  git config --global --add include.path "$managed_gitconfig"
fi

if [[ -n "${BOOTSTRAP_GIT_NAME:-}" ]]; then
  git config --global user.name "$BOOTSTRAP_GIT_NAME"
elif is_interactive && ! git config --global --get user.name >/dev/null 2>&1; then
  read -r -p "Configure Git user.name now? Enter a name or leave blank to skip: " git_name
  if [[ -n "$git_name" ]]; then
    git config --global user.name "$git_name"
  fi
fi

if [[ -n "${BOOTSTRAP_GIT_EMAIL:-}" ]]; then
  git config --global user.email "$BOOTSTRAP_GIT_EMAIL"
elif is_interactive && ! git config --global --get user.email >/dev/null 2>&1; then
  read -r -p "Configure Git user.email now? Enter an email or leave blank to skip: " git_email
  if [[ -n "$git_email" ]]; then
    git config --global user.email "$git_email"
  fi
fi

log "Installed managed Git include at ${managed_gitconfig}"
