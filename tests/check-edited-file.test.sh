#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/helpers.sh"
SUT="$HERE/../hooks/check-edited-file.sh"
TMP="$(mktemp -d)"; touch "$TMP/a.php" "$TMP/b.ts" "$TMP/c.txt"

out_php=$(echo "{\"tool_input\":{\"file_path\":\"$TMP/a.php\"}}" | FEATURE_GATE_DRY_RUN=1 bash "$SUT")
assert_contains "$out_php" "php -l" "routes .php to php -l"

out_ts=$(echo "{\"tool_input\":{\"file_path\":\"$TMP/b.ts\"}}" | FEATURE_GATE_DRY_RUN=1 bash "$SUT")
assert_contains "$out_ts" "eslint" "routes .ts to eslint"

out_txt=$(echo "{\"tool_input\":{\"file_path\":\"$TMP/c.txt\"}}" | FEATURE_GATE_DRY_RUN=1 bash "$SUT")
assert_eq "" "$out_txt" "ignores unsupported extension"

echo '{"tool_input":{}}' | FEATURE_GATE_DRY_RUN=1 bash "$SUT" >/dev/null 2>&1
assert_eq 0 "$?" "missing file_path -> exit 0"

rm -rf "$TMP"
finish
