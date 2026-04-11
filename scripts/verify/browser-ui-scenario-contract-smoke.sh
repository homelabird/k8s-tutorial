#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
README_FILE="$ROOT_DIR/scripts/verify/README.md"
PACKAGE_FILE="$ROOT_DIR/scripts/verify/package.json"
SMOKE_FILE="$ROOT_DIR/scripts/verify/browser-ui-smoke.mjs"
TMP_DIR="$(mktemp -d)"
ACTUAL_FILE="$TMP_DIR/actual.txt"
EXPECTED_FILE="$TMP_DIR/expected.txt"
README_LIST_FILE="$TMP_DIR/readme.txt"

cleanup() {
  rm -rf "$TMP_DIR"
}

trap cleanup EXIT

cat >"$EXPECTED_FILE" <<'EOF'
index-active-exam-warning
index-view-results-redirect
exam-terminal-toggle
exam-terminate-session
exam-review-mode-results
results-re-evaluation
results-evaluation-failed
results-retry-recovery
results-actions
results-feedback
EOF

grep -Fq '"browser-ui-smoke": "node browser-ui-smoke.mjs"' "$PACKAGE_FILE"
grep -Fq '"browser-ui-smoke:list": "node browser-ui-smoke.mjs --list"' "$PACKAGE_FILE"
grep -Fq "throw new Error('browser-ui-smoke:list does not open browser pages');" "$SMOKE_FILE"

(cd "$ROOT_DIR/scripts/verify" && npm run --silent browser-ui-smoke:list) >"$ACTUAL_FILE"
diff -u "$EXPECTED_FILE" "$ACTUAL_FILE"

awk '
  /The browser smoke currently runs these fixture-backed scenarios in order:/ {
    capture = 1
    next
  }
  capture && /^  - `/ {
    line = $0
    sub(/^  - `/, "", line)
    sub(/`$/, "", line)
    print line
    next
  }
  capture && !/^  - `/ {
    exit
  }
' "$README_FILE" >"$README_LIST_FILE"

diff -u "$EXPECTED_FILE" "$README_LIST_FILE"

scenario_count="$(wc -l <"$ACTUAL_FILE" | tr -d ' ')"
if [ "$scenario_count" -ne 10 ]; then
  echo "expected 10 browser smoke scenarios, found $scenario_count" >&2
  exit 1
fi

echo "browser ui scenario contract smoke passed"
