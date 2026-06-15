#!/usr/bin/env bash
# Minimal assertion helpers for the plugin's shell tests.
FAILED=0
assert_eq() { # expected actual label
  if [[ "$1" == "$2" ]]; then
    echo "PASS: $3"
  else
    echo "FAIL: $3 (expected '$1', got '$2')"; FAILED=1
  fi
}
assert_contains() { # haystack needle label
  if [[ "$1" == *"$2"* ]]; then
    echo "PASS: $3"
  else
    echo "FAIL: $3 (expected to contain '$2')"; FAILED=1
  fi
}
finish() { [[ "$FAILED" -eq 0 ]] && { echo "ALL PASSED"; exit 0; } || { echo "SOME FAILED"; exit 1; }; }
