#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RUNNER="$ROOT_DIR/scripts/verify/run-cka-2026-single-domain-drills.sh"
LABS_JSON="$ROOT_DIR/facilitator/assets/exams/labs.json"
FACILITATOR_README="$ROOT_DIR/facilitator/README.md"
TEMPLATE_README_NEXT5="$ROOT_DIR/docs/templates/cka-2026-next5/README.md"
TEMPLATE_README_NEXT3="$ROOT_DIR/docs/templates/cka-2026-next3/README.md"
TEMPLATE_README_NEXT4="$ROOT_DIR/docs/templates/cka-2026-next4/README.md"
TEMPLATE_README_NEXT3_OPS="$ROOT_DIR/docs/templates/cka-2026-next3-ops/README.md"
TEMPLATE_README_NEXT2_OPS="$ROOT_DIR/docs/templates/cka-2026-next2-ops/README.md"

EXPECTED_SUITES=(cka-006 cka-007 cka-008 cka-009 cka-010 cka-011 cka-012 cka-013 cka-014 cka-015 cka-016 cka-017 cka-018 cka-019 cka-020 cka-021 cka-022 cka-023 cka-024 cka-025)

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
grep -Fq 'Question `401` has now been promoted into facilitator pack `cka-014`.' "$TEMPLATE_README_NEXT4"
grep -Fq 'Question `402` has now been promoted into facilitator pack `cka-015`.' "$TEMPLATE_README_NEXT4"
grep -Fq 'Question `403` has now been promoted into facilitator pack `cka-016`.' "$TEMPLATE_README_NEXT4"
grep -Fq 'Question `404` has now been promoted into facilitator pack `cka-017`.' "$TEMPLATE_README_NEXT4"
grep -Fq 'Question `405` has now been promoted into facilitator pack `cka-018`.' "$TEMPLATE_README_NEXT4"
grep -Fq 'Question `501` has now been promoted into facilitator pack `cka-019`.' "$TEMPLATE_README_NEXT3_OPS"
grep -Fq 'Question `502` has now been promoted into facilitator pack `cka-020`.' "$TEMPLATE_README_NEXT3_OPS"
grep -Fq 'Question `503` has now been promoted into facilitator pack `cka-021`.' "$TEMPLATE_README_NEXT3_OPS"
grep -Fq 'Question `601` has now been promoted into facilitator pack `cka-022`.' "$TEMPLATE_README_NEXT2_OPS"
grep -Fq 'Question `602` has now been promoted into facilitator pack `cka-023`.' "$TEMPLATE_README_NEXT2_OPS"
grep -Fq 'Question `603` has now been promoted into facilitator pack `cka-024`.' "$TEMPLATE_README_NEXT2_OPS"
grep -Fq 'Question `604` has now been promoted into facilitator pack `cka-025`.' "$TEMPLATE_README_NEXT2_OPS"
grep -Fq './scripts/verify/run-cka-2026-single-domain-drills.sh --list' "$ROOT_DIR/scripts/verify/README.md"

echo 'cka-2026 single-domain contract smoke passed'
