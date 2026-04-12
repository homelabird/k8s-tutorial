#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RUNNER="$ROOT_DIR/scripts/verify/run-cka-2026-single-domain-drills.sh"
LABS_JSON="$ROOT_DIR/facilitator/assets/exams/labs.json"
FACILITATOR_README="$ROOT_DIR/facilitator/README.md"
TEMPLATE_README_NEXT5="$ROOT_DIR/docs/templates/cka-2026-next5/README.md"
TEMPLATE_README_NEXT3="$ROOT_DIR/docs/templates/cka-2026-next3/README.md"

EXPECTED_SUITES=(cka-006 cka-007 cka-008 cka-009 cka-010 cka-011 cka-012 cka-013)

mapfile -t actual_suites < <(bash "$RUNNER" --list)
printf '%s\n' "${actual_suites[@]}"
[ "${#actual_suites[@]}" -eq "${#EXPECTED_SUITES[@]}" ]
for index in "${!EXPECTED_SUITES[@]}"; do
  [ "${actual_suites[$index]}" = "${EXPECTED_SUITES[$index]}" ]
done

python3 - <<'PY' "$LABS_JSON" "${EXPECTED_SUITES[@]}"
import json
import sys
from pathlib import Path

labs_path = Path(sys.argv[1])
expected = sys.argv[2:]
payload = json.loads(labs_path.read_text())
if isinstance(payload, dict):
    entries = payload.get("labs", [])
elif isinstance(payload, list):
    entries = payload
else:
    raise SystemExit("unexpected labs.json structure")
ids = {item["id"] for item in entries if isinstance(item, dict) and "id" in item}
missing = [lab_id for lab_id in expected if lab_id not in ids]
if missing:
    raise SystemExit(f"missing promoted labs in labs.json: {', '.join(missing)}")
PY

for suite in "${EXPECTED_SUITES[@]}"; do
  suite_dir="$ROOT_DIR/facilitator/assets/exams/cka/${suite#cka-}"
  [ -d "$suite_dir" ]
  [ -f "$suite_dir/assessment.json" ]
  [ -f "$suite_dir/answers.md" ]
  [ -f "$suite_dir/scripts/setup/q1_setup.sh" ]
  find "$suite_dir/scripts/validation" -maxdepth 1 -type f -name 'q1_s*.sh' | sort >/tmp/$(basename "$suite_dir")-validators.txt
  [ "$(wc -l < /tmp/$(basename "$suite_dir")-validators.txt)" -eq 3 ]
  grep -Fq -- "$suite" "$FACILITATOR_README"
done

grep -Fq 'All five drafts have now been promoted into facilitator packs `cka-006` through `cka-010`.' "$TEMPLATE_README_NEXT5"
grep -Fq 'All three drafts have now been promoted into facilitator packs `cka-011` through `cka-013`.' "$TEMPLATE_README_NEXT3"
grep -Fq './scripts/verify/run-cka-2026-single-domain-drills.sh --list' "$ROOT_DIR/scripts/verify/README.md"

echo 'cka-2026 single-domain contract smoke passed'
