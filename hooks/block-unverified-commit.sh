#!/usr/bin/env bash
# PreToolUse(Bash): block `git commit` unless verification passes. Allow everything else.
set -uo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
input="$(cat)"
command="$(printf '%s' "$input" | jq -r '.tool_input.command // empty')"

# Returns 0 if the command string contains a git-commit invocation, 1 otherwise.
# Handles global flags between `git` and the subcommand (e.g. `git -c k=v commit`,
# `git -C path commit`, `git --no-pager commit`), env-var prefixes, and chained commands.
_is_git_commit() {
  local cmd="$1" fragment tok i next subcmd
  local -a tokens
  while IFS= read -r fragment || [[ -n "$fragment" ]]; do               # handle last line w/o trailing newline
    fragment="${fragment#"${fragment%%[![:space:]]*}"}"                 # ltrim
    while [[ "$fragment" =~ ^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]* ]]; do # drop env assignments
      fragment="${fragment#*[[:space:]]}"
      fragment="${fragment#"${fragment%%[![:space:]]*}"}"
    done
    read -ra tokens <<< "$fragment"
    i=0
    while (( i < ${#tokens[@]} )); do
      tok="${tokens[$i]}"
      if [[ "$tok" == "git" || "$tok" == */git ]]; then
        (( i++ ))
        while (( i < ${#tokens[@]} )); do                              # skip git global flags
          next="${tokens[$i]}"
          [[ "$next" != -* ]] && break
          [[ "$next" == "-c" || "$next" == "-C" || "$next" == "--git-dir" ||
             "$next" == "--work-tree" || "$next" == "--exec-path" ]] && (( i++ ))
          (( i++ ))
        done
        subcmd="${tokens[$i]:-}"
        [[ "$subcmd" == "commit" ]] && return 0
        break
      fi
      (( i++ ))
    done
  done < <(printf '%s' "$cmd" | tr ';&|' '\n')
  return 1
}

# Only gate git commits.
if ! _is_git_commit "$command"; then
  exit 0
fi

if bash "${PLUGIN_ROOT}/lib/run-verify.sh"; then
  exit 0   # verification passed -> allow the commit
else
  echo "feature-gate: verification failed — commit blocked. Fix tests/lint/types, then retry." >&2
  exit 2   # exit 2 = block the tool call; stderr is shown to the model
fi
