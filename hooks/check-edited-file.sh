#!/usr/bin/env bash
# PostToolUse(Edit|Write): run a per-file check on the edited file. Never blocks.
set -uo pipefail

input="$(cat)"
file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')"
[[ -z "$file_path" || ! -f "$file_path" ]] && exit 0

run_check() {
  if [[ "${FEATURE_GATE_DRY_RUN:-0}" == "1" ]]; then echo "would-run: $*"; return 0; fi
  "$@" 2>&1 || true   # advisory only
}

case "$file_path" in
  *.php)                  run_check php -l "$file_path" ;;
  *.ts|*.tsx|*.js|*.jsx)  run_check npx --no-install eslint "$file_path" ;;
esac
exit 0
