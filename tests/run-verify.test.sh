#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/helpers.sh"
SUT="$HERE/../lib/run-verify.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Case 1: config .verify exits 0 -> run-verify exits 0
echo '{"verify":"true"}' > "$TMP/.feature-gate.json"
CLAUDE_PROJECT_DIR="$TMP" bash "$SUT" >/dev/null 2>&1
assert_eq 0 "$?" "config verify 'true' -> exit 0"

# Case 2: config .verify exits non-zero -> run-verify propagates failure
echo '{"verify":"false"}' > "$TMP/.feature-gate.json"
CLAUDE_PROJECT_DIR="$TMP" bash "$SUT" >/dev/null 2>&1
assert_eq 1 "$?" "config verify 'false' -> exit 1"

# Case 3: no config -> uses default (overridable for the test)
rm -f "$TMP/.feature-gate.json"
CLAUDE_PROJECT_DIR="$TMP" FEATURE_GATE_DEFAULT_VERIFY="true" bash "$SUT" >/dev/null 2>&1
assert_eq 0 "$?" "no config -> default verify runs"

# Case 4: malformed JSON -> blocks (exit 2), does NOT silently fall back
echo '{bad' > "$TMP/.feature-gate.json"
CLAUDE_PROJECT_DIR="$TMP" bash "$SUT" >/dev/null 2>&1
assert_eq 2 "$?" "malformed JSON -> exit 2 (fail-closed)"

# Case 5: valid JSON, empty .verify -> falls back to default
echo '{"verify":""}' > "$TMP/.feature-gate.json"
CLAUDE_PROJECT_DIR="$TMP" FEATURE_GATE_DEFAULT_VERIFY="true" bash "$SUT" >/dev/null 2>&1
assert_eq 0 "$?" "empty .verify -> default verify runs"

# Case 6: valid JSON, null .verify -> treated as unset, falls back to default
echo '{"verify":null}' > "$TMP/.feature-gate.json"
CLAUDE_PROJECT_DIR="$TMP" FEATURE_GATE_DEFAULT_VERIFY="true" bash "$SUT" >/dev/null 2>&1
assert_eq 0 "$?" "null .verify -> default verify runs"

finish
