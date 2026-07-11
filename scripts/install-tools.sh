#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=scripts/lib.sh
. "${ROOT_DIR}/scripts/lib.sh"

require_not_root

MISE=$(mise_bin) || die "mise is not installed or not on PATH."

export MISE_YES=1
eval "$("$MISE" activate bash)"

tools_to_install=(
  java@temurin-11
  java@temurin-17
  java@temurin-21
  java@temurin-25
  node@24
  pnpm@10
  maven@latest
  npm:@openai/codex
)

ensure_remote_version() {
  local plugin=$1
  local pattern=$2
  local description=$3

  if ! "$MISE" ls-remote "$plugin" | grep -qE "$pattern"; then
    die "mise did not report an available ${description}. The upstream version identifier may have changed."
  fi
}

ensure_remote_version java '^temurin-11(\.|$)' 'Temurin Java 11 version'
ensure_remote_version java '^temurin-17(\.|$)' 'Temurin Java 17 version'
ensure_remote_version java '^temurin-21(\.|$)' 'Temurin Java 21 version'
ensure_remote_version java '^temurin-25(\.|$)' 'Temurin Java 25 version'
ensure_remote_version node '^24\.' 'Node.js 24 version'
ensure_remote_version pnpm '^10\.' 'pnpm 10 version'

for tool in "${tools_to_install[@]}"; do
  log "Ensuring ${tool} is available"
  "$MISE" install "$tool"
done

"$MISE" upgrade \
  java@temurin-11 \
  java@temurin-17 \
  java@temurin-21 \
  java@temurin-25 \
  node@24 \
  pnpm@10 \
  maven@latest \
  npm:@openai/codex

"$MISE" use --global java@temurin-25
"$MISE" use --global node@24
"$MISE" use --global pnpm@10
"$MISE" use --global maven@latest
"$MISE" use --global npm:@openai/codex

"$MISE" reshim || true

log "Java 25, Node.js 24, pnpm 10, Maven, and Codex CLI are configured as global mise defaults"
