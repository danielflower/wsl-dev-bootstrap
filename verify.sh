#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib.sh
. "${ROOT_DIR}/scripts/lib.sh"

failures=0

pass() { printf '[PASS] %s\n' "$*"; }
warn_check() { printf '[WARN] %s\n' "$*" >&2; }
fail() {
  printf '[FAIL] %s\n' "$*" >&2
  failures=$((failures + 1))
}

require_cmd() {
  local cmd=$1
  if command -v "$cmd" >/dev/null 2>&1; then
    pass "${cmd} is installed"
  else
    fail "${cmd} is not installed"
  fi
}

if require_ubuntu_wsl >/dev/null 2>&1; then
  pass "Ubuntu WSL detected"
else
  fail "Ubuntu WSL was not detected"
fi

require_cmd git
require_cmd gh

if MISE=$(mise_bin); then
  pass "mise is available at ${MISE}"
else
  fail "mise is not available"
  MISE=
fi

if [[ -n "$MISE" ]]; then
  export MISE_YES=1
  eval "$("$MISE" activate bash)"

  for version in 11 17 21 25; do
    if "$MISE" where "java@temurin-${version}" >/dev/null 2>&1; then
      pass "Java ${version} is installed"
    else
      fail "Java ${version} is not installed through mise"
    fi
  done

  if java -version 2>&1 | grep -qE 'version "25\.|openjdk 25\.'; then
    pass "active java reports version 25"
  else
    fail "active java does not report version 25"
  fi

  if [[ -n "${JAVA_HOME:-}" && -x "${JAVA_HOME}/bin/java" ]]; then
    pass "JAVA_HOME points to an installed Java runtime: ${JAVA_HOME}"
  else
    fail "JAVA_HOME is not set to an installed Java runtime"
  fi

  if node --version 2>/dev/null | grep -qE '^v24\.'; then
    pass "Node.js 24 is active"
  else
    fail "Node.js 24 is not active"
  fi

  if pnpm --version 2>/dev/null | grep -qE '^10\.'; then
    pass "pnpm 10 is active"
  else
    fail "pnpm 10 is not active"
  fi

  if codex --version >/dev/null 2>&1; then
    pass "Codex CLI works"
  else
    fail "Codex CLI does not work"
  fi

  if npm --version >/dev/null 2>&1; then
    pass "npm works"
  else
    fail "npm does not work"
  fi

  if mvn_output=$(mvn --version 2>/dev/null); then
    pass "Maven works"
    maven_runtime=$(printf '%s\n' "$mvn_output" | sed -nE 's/^Java version: .* runtime: (.*)$/\1/p' | head -n 1)
    if [[ -n "$maven_runtime" && -x "${maven_runtime}/bin/java" ]]; then
      pass "Maven uses installed Java runtime: ${maven_runtime}"
    else
      fail "Maven did not report a valid installed Java runtime"
    fi
  else
    fail "Maven does not work"
  fi
fi

if command -v gh >/dev/null 2>&1; then
  if gh auth status --hostname github.com >/dev/null 2>&1; then
    pass "GitHub CLI is authenticated for github.com"
  else
    warn_check "GitHub CLI is intentionally unauthenticated or login has not been completed"
  fi
fi

if [[ "$failures" -gt 0 ]]; then
  printf '%s required verification check(s) failed.\n' "$failures" >&2
  exit 1
fi

printf 'All required verification checks passed.\n'
