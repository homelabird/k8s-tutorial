#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORKFLOW_FILE="$ROOT_DIR/.github/workflows/cka-2026-regressions.yml"

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

require_fixed 'name: CKA 2026 Regressions'
require_fixed 'workflow_dispatch:'
require_fixed 'schedule:'
require_fixed '- cron: "0 18 * * *"'
require_fixed 'contents: read'
require_fixed 'group: cka-2026-regressions'
require_fixed 'cancel-in-progress: false'
require_fixed 'run-cka-2026-regressions:'
require_fixed 'runs-on:'
require_fixed '      - self-hosted'
require_fixed '      - linux'
require_fixed 'timeout-minutes: 180'

require_fixed '      suites:'
require_fixed '        description: "Space-separated suites to run. Leave empty for all."'
require_fixed '        default: ""'
require_fixed '        type: string'
require_fixed '      suite_timeout_seconds:'
require_fixed '        description: "Per-suite timeout passed to the aggregated runner."'
require_fixed '        default: "2400"'
require_fixed '      pack_success_diagnostics:'
require_fixed '        description: "Pack diagnostics on success too. Failure runs always pack."'
require_fixed '        default: false'
require_fixed '        type: boolean'

require_fixed "      SUITES_INPUT: \${{ github.event_name == 'workflow_dispatch' && inputs.suites || '' }}"
require_fixed "      SUITE_TIMEOUT_SECONDS: \${{ github.event_name == 'workflow_dispatch' && inputs.suite_timeout_seconds || '2400' }}"
require_fixed "      PACK_SUCCESS_DIAGNOSTICS: \${{ github.event_name == 'workflow_dispatch' && inputs.pack_success_diagnostics || false }}"
require_fixed '      ARTIFACT_DIR: .artifacts/cka-2026'
require_fixed '      ARTIFACT_ARCHIVE: .artifacts/cka-2026.tar.gz'
require_fixed '      SUMMARY_PATH: .artifacts/cka-2026/summary.txt'

require_fixed 'suite_timeout_seconds must be a non-negative integer: ${SUITE_TIMEOUT_SECONDS}'
require_fixed 'bash scripts/verify/run-cka-2026-regressions.sh "${suite_args[@]}"'
require_fixed 'bash scripts/verify/run-cka-2026-regressions.sh \'
require_fixed 'tee "${ARTIFACT_DIR}/regression-run.log"'
require_fixed 'chmod +x scripts/verify/pack-cka-2026-diagnostics.sh'
require_fixed './scripts/verify/pack-cka-2026-diagnostics.sh "${ARTIFACT_DIR}" "${ARTIFACT_ARCHIVE}"'
require_fixed 'chmod +x scripts/verify/render-cka-2026-summary-markdown.sh'
require_fixed 'scripts/verify/render-cka-2026-summary-markdown.sh "${SUMMARY_PATH}" >> "${GITHUB_STEP_SUMMARY}"'
require_fixed 'name: Upload regression summary'
require_fixed 'name: Upload regression run log'
require_fixed 'name: Upload packed diagnostics archive'
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
  '      - name: Prepare artifact directory' \
  '      - name: Show selected regression suites' \
  '      - name: Verify Podman availability' \
  '      - name: Run CKA 2026 regressions' \
  '      - name: Pack regression diagnostics' \
  '      - name: Publish regression summary to workflow UI' \
  '      - name: Upload regression summary' \
  '      - name: Upload regression run log' \
  '      - name: Upload packed diagnostics archive'

echo "cka-2026 workflow contract smoke passed"
