#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/verify/cka-2026-single-domain-inventory.sh --all
  ./scripts/verify/cka-2026-single-domain-inventory.sh --nightly-lanes
  ./scripts/verify/cka-2026-single-domain-inventory.sh --nightly-describe
  LANE_INPUT="rbac-storage host-dns" ./scripts/verify/cka-2026-single-domain-inventory.sh --nightly-matrix-json

Options:
  --all                Print the promoted cka-006..cka-050 single-domain suites.
  --nightly-lanes      Print the nightly sample lane names.
  --nightly-describe   Print the nightly sample lanes with suite coverage notes.
  --nightly-matrix-json
                       Emit GitHub Actions outputs for the nightly lane matrix.

Notes:
  - Use LANE_INPUT="lane-a lane-b" with --nightly-matrix-json to select a subset.
  - Without LANE_INPUT, --nightly-matrix-json emits the full balanced nightly sample.
EOF
}

emit_all_suites() {
  printf '%s\n' \
    cka-006 cka-007 cka-008 cka-009 cka-010 cka-011 cka-012 cka-013 cka-014 \
    cka-015 cka-016 cka-017 cka-018 cka-019 cka-020 cka-021 cka-022 cka-023 \
    cka-024 cka-025 cka-026 cka-027 cka-028 cka-029 cka-030 cka-031 cka-032 \
    cka-033 cka-034 cka-035 cka-036 cka-037 cka-038 cka-039 cka-040 cka-041 \
    cka-042 cka-043 cka-044 cka-045 cka-046 cka-047 cka-048 cka-049 cka-050
}

emit_nightly_records() {
  cat <<'EOF'
rbac-storage	cka-006 cka-010	namespace auth plus persistent volume repair hands-on coverage
traffic-observability	cka-014 cka-015	gateway routing plus logs and kubectl top hands-on coverage
operator-controlplane	cka-017 cka-018	operator install checks plus etcd recovery planning coverage
runtime-pki	cka-023 cka-025	PKI renewal guidance plus CRI endpoint diagnostics coverage
workload-policy	cka-032 cka-037	probe contract review plus PriorityClass policy coverage
host-dns	cka-043 cka-048	static pod manifest review plus pod DNS policy coverage
EOF
}

emit_nightly_matrix_json() {
  local nightly_records
  nightly_records="$(emit_nightly_records)"

  NIGHTLY_RECORDS="$nightly_records" LANE_INPUT="${LANE_INPUT:-}" python3 - <<'PY'
import json
import os

records = []
for line in os.environ.get("NIGHTLY_RECORDS", "").splitlines():
    lane, suites, coverage = line.rstrip("\n").split("\t")
    records.append(
        {
            "lane": lane,
            "suites": suites,
            "coverage": coverage,
        }
    )

requested = os.environ.get("LANE_INPUT", "").split()
valid = [record["lane"] for record in records]
selected = requested or valid
unknown = [lane for lane in selected if lane not in valid]

if unknown:
    raise SystemExit(f"unknown nightly lane selection: {' '.join(unknown)}")

index = {record["lane"]: record for record in records}
include = [index[lane] for lane in selected]

print(f"matrix={json.dumps({'include': include}, separators=(',', ':'))}")
print(f"lanes_text={' '.join(selected)}")
PY
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ "$#" -eq 0 ]; then
  usage
  exit 0
fi

case "$1" in
  --all)
    emit_all_suites
    ;;
  --nightly-lanes)
    emit_nightly_records | cut -f1
    ;;
  --nightly-describe)
    emit_nightly_records | awk -F '\t' '{printf "%s | %s | %s\n", $1, $2, $3}'
    ;;
  --nightly-matrix-json)
    emit_nightly_matrix_json
    ;;
  *)
    echo "Unknown option: $1" >&2
    usage >&2
    exit 1
    ;;
esac
