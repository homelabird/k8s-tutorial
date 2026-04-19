#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RUNNER="$ROOT_DIR/scripts/verify/run-cka-2026-single-domain-drills.sh"
INVENTORY="$ROOT_DIR/scripts/verify/cka-2026-single-domain-inventory.sh"
LABS_JSON="$ROOT_DIR/facilitator/assets/exams/labs.json"
FACILITATOR_README="$ROOT_DIR/facilitator/README.md"
TEMPLATE_README_NEXT5="$ROOT_DIR/docs/templates/cka-2026-next5/README.md"
TEMPLATE_README_NEXT3="$ROOT_DIR/docs/templates/cka-2026-next3/README.md"
TEMPLATE_README_NEXT4="$ROOT_DIR/docs/templates/cka-2026-next4/README.md"
TEMPLATE_README_NEXT3_OPS="$ROOT_DIR/docs/templates/cka-2026-next3-ops/README.md"
TEMPLATE_README_NEXT2_OPS="$ROOT_DIR/docs/templates/cka-2026-next2-ops/README.md"
TEMPLATE_README_NEXT1_STORAGE="$ROOT_DIR/docs/templates/cka-2026-next1-storage/README.md"
TEMPLATE_README_NEXT1_DISRUPTION="$ROOT_DIR/docs/templates/cka-2026-next1-disruption/README.md"
TEMPLATE_README_NEXT1_STATEFUL="$ROOT_DIR/docs/templates/cka-2026-next1-stateful/README.md"
TEMPLATE_README_NEXT1_DAEMONSET="$ROOT_DIR/docs/templates/cka-2026-next1-daemonset/README.md"
TEMPLATE_README_NEXT1_CRONJOB="$ROOT_DIR/docs/templates/cka-2026-next1-cronjob/README.md"
TEMPLATE_README_NEXT1_JOB="$ROOT_DIR/docs/templates/cka-2026-next1-job/README.md"
TEMPLATE_README_NEXT1_PROBES="$ROOT_DIR/docs/templates/cka-2026-next1-probes/README.md"
TEMPLATE_README_NEXT1_INITCONTAINER="$ROOT_DIR/docs/templates/cka-2026-next1-initcontainer/README.md"
TEMPLATE_README_NEXT1_AFFINITY="$ROOT_DIR/docs/templates/cka-2026-next1-affinity/README.md"
TEMPLATE_README_NEXT1_SERVICEACCOUNT="$ROOT_DIR/docs/templates/cka-2026-next1-serviceaccount/README.md"
TEMPLATE_README_NEXT1_SECURITYCONTEXT="$ROOT_DIR/docs/templates/cka-2026-next1-securitycontext/README.md"
TEMPLATE_README_NEXT1_PRIORITYCLASS="$ROOT_DIR/docs/templates/cka-2026-next1-priorityclass/README.md"
TEMPLATE_README_NEXT1_QOS="$ROOT_DIR/docs/templates/cka-2026-next1-qos/README.md"
TEMPLATE_README_NEXT1_IMAGEPULLSECRET="$ROOT_DIR/docs/templates/cka-2026-next1-imagepullsecret/README.md"
TEMPLATE_README_NEXT1_PVRECLAIM="$ROOT_DIR/docs/templates/cka-2026-next1-pvreclaim/README.md"
TEMPLATE_README_NEXT1_PVRESIZE="$ROOT_DIR/docs/templates/cka-2026-next1-pvresize/README.md"
TEMPLATE_README_NEXT1_EPHEMERALDEBUG="$ROOT_DIR/docs/templates/cka-2026-next1-ephemeraldebug/README.md"
TEMPLATE_README_NEXT1_STATICPOD="$ROOT_DIR/docs/templates/cka-2026-next1-staticpod/README.md"
TEMPLATE_README_NEXT1_PROJECTEDVOLUME="$ROOT_DIR/docs/templates/cka-2026-next1-projectedvolume/README.md"
TEMPLATE_README_NEXT1_ENVFROM="$ROOT_DIR/docs/templates/cka-2026-next1-envfrom/README.md"
TEMPLATE_README_NEXT1_SUBPATH="$ROOT_DIR/docs/templates/cka-2026-next1-subpath/README.md"
TEMPLATE_README_NEXT1_RWOP="$ROOT_DIR/docs/templates/cka-2026-next1-rwop/README.md"
TEMPLATE_README_NEXT1_DNSPOLICY="$ROOT_DIR/docs/templates/cka-2026-next1-dnspolicy/README.md"
TEMPLATE_README_NEXT1_LIFECYCLE="$ROOT_DIR/docs/templates/cka-2026-next1-lifecycle/README.md"
TEMPLATE_README_NEXT1_DOWNWARDAPI="$ROOT_DIR/docs/templates/cka-2026-next1-downwardapi/README.md"
TEMPLATE_README_NEXT1_TAINTS="$ROOT_DIR/docs/templates/cka-2026-next1-taints/README.md"

mapfile -t EXPECTED_SUITES < <(bash "$INVENTORY" --all)

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

required = ("assetPath", "category", "description", "difficulty", "examDurationInMinutes", "name", "track", "warmUpTimeInSeconds")
by_id = {item["id"]: item for item in entries if isinstance(item, dict) and "id" in item}
planning_focused = {"cka-016", "cka-018", "cka-019", "cka-022", "cka-023", "cka-025", "cka-027"}
ops_diagnostics = {"cka-024", "cka-026"}
for lab_id in expected:
    entry = by_id[lab_id]
    missing_fields = [field for field in required if field not in entry]
    if missing_fields:
        raise SystemExit(f"{lab_id} missing required metadata fields: {', '.join(missing_fields)}")
    if entry["assetPath"] != f"assets/exams/cka/{lab_id.split('-', 1)[1]}":
        raise SystemExit(f"{lab_id} has unexpected assetPath: {entry['assetPath']}")
    if entry["category"] != "CKA":
        raise SystemExit(f"{lab_id} has unexpected category: {entry['category']}")
    if entry["difficulty"] != "Medium":
        raise SystemExit(f"{lab_id} has unexpected difficulty: {entry['difficulty']}")
    if entry["examDurationInMinutes"] != 20:
        raise SystemExit(f"{lab_id} has unexpected examDurationInMinutes: {entry['examDurationInMinutes']}")
    if entry["warmUpTimeInSeconds"] != 90:
        raise SystemExit(f"{lab_id} has unexpected warmUpTimeInSeconds: {entry['warmUpTimeInSeconds']}")
    if not isinstance(entry["description"], str) or not entry["description"].strip():
        raise SystemExit(f"{lab_id} must include a non-empty description")
    if lab_id in planning_focused:
        expected_track = "planning-focused"
    elif lab_id in ops_diagnostics:
        expected_track = "ops-diagnostics"
    else:
        expected_track = "hands-on"
    if entry["track"] != expected_track:
        raise SystemExit(f"{lab_id} has unexpected track: {entry['track']}")
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
grep -Fq 'Question `701` has now been promoted into facilitator pack `cka-026`.' "$TEMPLATE_README_NEXT1_STORAGE"
grep -Fq 'Question `801` has now been promoted into facilitator pack `cka-027`.' "$TEMPLATE_README_NEXT1_DISRUPTION"
grep -Fq 'Question `901` has now been promoted into facilitator pack `cka-028`.' "$TEMPLATE_README_NEXT1_STATEFUL"
grep -Fq 'Question `1001` has now been promoted into facilitator pack `cka-029`.' "$TEMPLATE_README_NEXT1_DAEMONSET"
grep -Fq 'Question `1101` has now been promoted into facilitator pack `cka-030`.' "$TEMPLATE_README_NEXT1_CRONJOB"
grep -Fq 'Question `1201` has now been promoted into facilitator pack `cka-031`.' "$TEMPLATE_README_NEXT1_JOB"
grep -Fq 'Question `1301` has now been promoted into facilitator pack `cka-032`.' "$TEMPLATE_README_NEXT1_PROBES"
grep -Fq 'Question `1401` has now been promoted into facilitator pack `cka-033`.' "$TEMPLATE_README_NEXT1_INITCONTAINER"
grep -Fq 'Question `1501` has now been promoted into facilitator pack `cka-034`.' "$TEMPLATE_README_NEXT1_AFFINITY"
grep -Fq 'Question `1601` has now been promoted into facilitator pack `cka-035`.' "$TEMPLATE_README_NEXT1_SERVICEACCOUNT"
grep -Fq 'Question `1701` has now been promoted into facilitator pack `cka-036`.' "$TEMPLATE_README_NEXT1_SECURITYCONTEXT"
grep -Fq 'Question `1801` has now been promoted into facilitator pack `cka-037`.' "$TEMPLATE_README_NEXT1_PRIORITYCLASS"
grep -Fq 'Question `1901` has now been promoted into facilitator pack `cka-038`.' "$TEMPLATE_README_NEXT1_QOS"
grep -Fq 'Question `2001` has now been promoted into facilitator pack `cka-039`.' "$TEMPLATE_README_NEXT1_IMAGEPULLSECRET"
grep -Fq 'Question `2101` has now been promoted into facilitator pack `cka-040`.' "$TEMPLATE_README_NEXT1_PVRECLAIM"
grep -Fq 'Question `2201` has now been promoted into facilitator pack `cka-041`.' "$TEMPLATE_README_NEXT1_PVRESIZE"
grep -Fq 'Question `2301` has now been promoted into facilitator pack `cka-042`.' "$TEMPLATE_README_NEXT1_EPHEMERALDEBUG"
grep -Fq 'Question `2401` has now been promoted into facilitator pack `cka-043`.' "$TEMPLATE_README_NEXT1_STATICPOD"
grep -Fq 'Question `2501` has now been promoted into facilitator pack `cka-044`.' "$TEMPLATE_README_NEXT1_PROJECTEDVOLUME"
grep -Fq 'Question `2601` has now been promoted into facilitator pack `cka-045`.' "$TEMPLATE_README_NEXT1_ENVFROM"
grep -Fq 'Question `2701` has now been promoted into facilitator pack `cka-046`.' "$TEMPLATE_README_NEXT1_SUBPATH"
grep -Fq 'Question `2801` has now been promoted into facilitator pack `cka-047`.' "$TEMPLATE_README_NEXT1_RWOP"
grep -Fq 'Question `4801` has now been promoted into facilitator pack `cka-048`.' "$TEMPLATE_README_NEXT1_DNSPOLICY"
grep -Fq 'Question `4901` has now been promoted into facilitator pack `cka-049`.' "$TEMPLATE_README_NEXT1_LIFECYCLE"
grep -Fq 'Question `5001` has now been promoted into facilitator pack `cka-050`.' "$TEMPLATE_README_NEXT1_DOWNWARDAPI"
grep -Fq 'Question `5101` has now been promoted into facilitator pack `cka-051`.' "$TEMPLATE_README_NEXT1_TAINTS"
grep -Fq './scripts/verify/run-cka-2026-single-domain-drills.sh --list' "$ROOT_DIR/scripts/verify/README.md"

echo 'cka-2026 single-domain contract smoke passed'
