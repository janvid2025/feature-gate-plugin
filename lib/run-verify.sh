#!/usr/bin/env bash
# Resolve and run the target project's verification command.
# Source of truth: ${CLAUDE_PROJECT_DIR}/.feature-gate.json -> .verify (a shell command string).
# Falls back to a safe default. NEVER put React Native jest in a local verify command (it OOMs).
set -uo pipefail

project_dir="${CLAUDE_PROJECT_DIR:-$PWD}"
config="${project_dir}/.feature-gate.json"
default_cmd="${FEATURE_GATE_DEFAULT_VERIFY:-npm run typecheck && npm run lint}"

if [[ -f "$config" ]]; then
  if ! verify_cmd="$(jq -r '.verify // empty' "$config" 2>/dev/null)"; then
    echo "[feature-gate] ERROR: failed to parse $config — blocking (fix the config)." >&2
    exit 2
  fi
  [[ -z "$verify_cmd" ]] && verify_cmd="$default_cmd"
else
  verify_cmd="$default_cmd"
fi

echo "[feature-gate] verify: ${verify_cmd}" >&2
# -e intentionally omitted: `exec` replaces this process, so the verify command's
# exit code becomes this script's exit code (0=pass, non-zero=block the commit).
exec bash -c "$verify_cmd"
