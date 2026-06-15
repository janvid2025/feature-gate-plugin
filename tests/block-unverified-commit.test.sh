#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/helpers.sh"
unset CLAUDE_PROJECT_DIR   # hermetic: force the default-verify path, ignore any ambient project config
SUT="$HERE/../hooks/block-unverified-commit.sh"
export CLAUDE_PLUGIN_ROOT="$HERE/.."

# Case 1: non-commit command is allowed (exit 0), verify never runs
echo '{"tool_input":{"command":"ls -la"}}' | bash "$SUT" >/dev/null 2>&1
assert_eq 0 "$?" "non-commit command allowed"

# Case 2: git commit with passing verify -> allowed (exit 0)
echo '{"tool_input":{"command":"git commit -m x"}}' | FEATURE_GATE_DEFAULT_VERIFY="true" bash "$SUT" >/dev/null 2>&1
assert_eq 0 "$?" "git commit allowed when verify passes"

# Case 3: git commit with failing verify -> blocked (exit 2)
echo '{"tool_input":{"command":"git commit -m x"}}' | FEATURE_GATE_DEFAULT_VERIFY="false" bash "$SUT" >/dev/null 2>&1
assert_eq 2 "$?" "git commit blocked when verify fails"

# Case 4: -c flag before commit -> still gated
echo '{"tool_input":{"command":"git -c commit.gpgsign=false commit -m x"}}' | FEATURE_GATE_DEFAULT_VERIFY="false" bash "$SUT" >/dev/null 2>&1
assert_eq 2 "$?" "git -c ... commit is gated"

# Case 5: -C path before commit -> still gated
echo '{"tool_input":{"command":"git -C /repo commit -m x"}}' | FEATURE_GATE_DEFAULT_VERIFY="false" bash "$SUT" >/dev/null 2>&1
assert_eq 2 "$?" "git -C path commit is gated"

# Case 6: double-spaced git commit -> still gated
echo '{"tool_input":{"command":"git  commit -m x"}}' | FEATURE_GATE_DEFAULT_VERIFY="false" bash "$SUT" >/dev/null 2>&1
assert_eq 2 "$?" "double-spaced git commit is gated"

# Case 7: non-commit git command passes through WITHOUT running verify
echo '{"tool_input":{"command":"git log --oneline"}}' | FEATURE_GATE_DEFAULT_VERIFY="false" bash "$SUT" >/dev/null 2>&1
assert_eq 0 "$?" "git log passes through ungated"

finish
