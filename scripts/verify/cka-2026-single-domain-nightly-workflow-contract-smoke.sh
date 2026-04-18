#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORKFLOW_FILE="$ROOT_DIR/.github/workflows/cka-2026-single-domain-nightly.yml"
INVENTORY_SCRIPT="$ROOT_DIR/scripts/verify/cka-2026-single-domain-inventory.sh"

require_fixed() {
  local needle="$1"
  grep -Fq -- "$needle" "$WORKFLOW_FILE"
}

line_no() {
  local pattern="$1"
  rg -n --fixed-strings -- "$pattern" "$WORKFLOW_FILE" | head -n 1 | cut -d: -f1
}

require_order() {
  local previous current
  previous="$(line_no "$1")"
  shift

  if [ -z "$previous" ]; then
    echo "missing workflow line: $1" >&2
    exit 1
  fi

  for current_label in "$@"; do
    current="$(line_no "$current_label")"
    if [ -z "$current" ]; then
      echo "missing workflow line: $current_label" >&2
      exit 1
    fi
    if [ "$current" -le "$previous" ]; then
      echo "workflow ordering regression between '$1' and '$current_label'" >&2
      exit 1
    fi
    previous="$current"
  done
}

mapfile -t nightly_lanes < <(bash "$INVENTORY_SCRIPT" --nightly-lanes)
[ "${#nightly_lanes[@]}" -eq 6 ]
[ "${nightly_lanes[0]}" = "rbac-storage" ]
[ "${nightly_lanes[5]}" = "host-dns" ]

nightly_describe="$(bash "$INVENTORY_SCRIPT" --nightly-describe)"
grep -Fq 'rbac-storage | cka-006 cka-010 | namespace auth plus persistent volume repair hands-on coverage' <<<"$nightly_describe"
grep -Fq 'traffic-observability | cka-014 cka-015 | gateway routing plus logs and kubectl top hands-on coverage' <<<"$nightly_describe"
grep -Fq 'host-dns | cka-043 cka-048 | static pod manifest review plus pod DNS policy coverage' <<<"$nightly_describe"

matrix_output="$(LANE_INPUT='rbac-storage host-dns' bash "$INVENTORY_SCRIPT" --nightly-matrix-json)"
grep -Fq 'lanes_text=rbac-storage host-dns' <<<"$matrix_output"
grep -Fq '"lane":"rbac-storage"' <<<"$matrix_output"
grep -Fq '"suites":"cka-006 cka-010"' <<<"$matrix_output"
grep -Fq '"lane":"host-dns"' <<<"$matrix_output"
grep -Fq '"suites":"cka-043 cka-048"' <<<"$matrix_output"

require_fixed 'name: CKA 2026 Single-Domain Nightly'
require_fixed 'workflow_dispatch:'
require_fixed 'schedule:'
require_fixed '- cron: "30 2 * * *"'
require_fixed 'contents: read'
require_fixed 'group: cka-2026-single-domain-nightly'
require_fixed 'cancel-in-progress: false'
require_fixed 'plan-single-domain-lanes:'
require_fixed 'run-single-domain-lanes:'
require_fixed 'runs-on: ubuntu-latest'
require_fixed '      - self-hosted'
require_fixed '      - linux'
require_fixed 'timeout-minutes: 180'
require_fixed '      max-parallel: 1'

require_fixed '      lanes:'
require_fixed '        description: "Space-separated nightly sample lanes to run. Leave empty for the balanced sample."'
require_fixed '        default: ""'
require_fixed '        type: string'
require_fixed '      suite_timeout_seconds:'
require_fixed '        description: "Per-suite timeout passed to the single-domain runner."'
require_fixed '        default: "1800"'
require_fixed '      pack_success_diagnostics:'
require_fixed '        description: "Pack diagnostics on success too. Failure runs always pack."'
require_fixed '        default: false'
require_fixed '        type: boolean'

require_fixed '      matrix: ${{ steps.plan.outputs.matrix }}'
require_fixed '      lanes_text: ${{ steps.plan.outputs.lanes_text }}'
require_fixed '      - name: Build single-domain nightly matrix'
require_fixed 'bash scripts/verify/cka-2026-single-domain-inventory.sh --nightly-matrix-json >> "${GITHUB_OUTPUT}"'
require_fixed '      matrix: ${{ fromJson(needs.plan-single-domain-lanes.outputs.matrix) }}'
require_fixed "      SUITE_TIMEOUT_SECONDS: \${{ github.event_name == 'workflow_dispatch' && inputs.suite_timeout_seconds || '1800' }}"
require_fixed "      PACK_SUCCESS_DIAGNOSTICS: \${{ github.event_name == 'workflow_dispatch' && inputs.pack_success_diagnostics || false }}"
require_fixed '      ARTIFACT_DIR: .artifacts/cka-2026-single-domain/${{ matrix.lane }}'
require_fixed '      ARTIFACT_ARCHIVE: .artifacts/cka-2026-single-domain/${{ matrix.lane }}.tar.gz'
require_fixed '      SUMMARY_PATH: .artifacts/cka-2026-single-domain/${{ matrix.lane }}/summary.txt'

require_fixed 'suite_timeout_seconds must be a non-negative integer: ${SUITE_TIMEOUT_SECONDS}'
require_fixed 'read -r -a suite_args <<< "${{ matrix.suites }}"'
require_fixed 'bash scripts/verify/run-cka-2026-single-domain-drills.sh "${suite_args[@]}"'
require_fixed 'tee "${ARTIFACT_DIR}/run.log"'
require_fixed 'chmod +x scripts/verify/pack-cka-2026-diagnostics.sh'
require_fixed './scripts/verify/pack-cka-2026-diagnostics.sh "${ARTIFACT_DIR}" "${ARTIFACT_ARCHIVE}"'
require_fixed 'chmod +x scripts/verify/render-cka-2026-summary-markdown.sh'
require_fixed 'scripts/verify/render-cka-2026-summary-markdown.sh "${SUMMARY_PATH}" >> "${GITHUB_STEP_SUMMARY}"'
require_fixed 'name: Upload nightly lane summary'
require_fixed 'name: Upload nightly lane run log'
require_fixed 'name: Upload nightly lane diagnostics archive'
require_fixed 'actions/upload-artifact@v4'

failure_condition_count="$(grep -Fc "failure() || (github.event_name == 'workflow_dispatch' && inputs.pack_success_diagnostics)" "$WORKFLOW_FILE")"
if [ "$failure_condition_count" -ne 4 ]; then
  echo "expected 4 pack_success_diagnostics failure guards, found $failure_condition_count" >&2
  exit 1
fi

artifact_upload_count="$(grep -Fc 'uses: actions/upload-artifact@v4' "$WORKFLOW_FILE")"
if [ "$artifact_upload_count" -ne 3 ]; then
  echo "expected 3 artifact upload steps, found $artifact_upload_count" >&2
  exit 1
fi

require_order \
  '      - name: Prepare lane artifact directory' \
  '      - name: Show selected nightly lane' \
  '      - name: Verify Podman availability' \
  '      - name: Run selected nightly sample lane' \
  '      - name: Pack nightly lane diagnostics' \
  '      - name: Publish nightly lane summary to workflow UI' \
  '      - name: Upload nightly lane summary' \
  '      - name: Upload nightly lane run log' \
  '      - name: Upload nightly lane diagnostics archive'

echo "cka-2026 single-domain nightly workflow contract smoke passed"
