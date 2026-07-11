#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

scripts=(
  bootstrap.sh
  verify.sh
  scripts/install-apt-packages.sh
  scripts/install-github-cli.sh
  scripts/install-mise.sh
  scripts/install-tools.sh
  scripts/configure-shell.sh
  scripts/configure-git.sh
  scripts/authenticate-github.sh
  scripts/use-java
  scripts/lib.sh
)

for script in "${scripts[@]}"; do
  bash -n "${ROOT_DIR}/${script}"
  if [[ ! -x "${ROOT_DIR}/${script}" ]]; then
    printf 'Script is not executable: %s\n' "$script" >&2
    exit 1
  fi
done

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck "${scripts[@]/#/${ROOT_DIR}/}"
else
  printf 'shellcheck not installed; skipped ShellCheck.\n' >&2
fi

if grep -RInE '(ghp_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,}|-----BEGIN (RSA|OPENSSH|EC|DSA)? ?PRIVATE KEY-----|AKIA[0-9A-Z]{16})' \
  "${ROOT_DIR}" \
  --exclude-dir=.git; then
  printf 'Potential secret pattern found.\n' >&2
  exit 1
fi

printf 'Smoke test passed.\n'
