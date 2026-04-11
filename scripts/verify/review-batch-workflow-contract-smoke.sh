#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORKFLOW_FILE="$ROOT_DIR/.github/workflows/review-batch-checks.yml"

require_fixed() {
  local needle="$1"
  grep -Fq -- "$needle" "$WORKFLOW_FILE"
}

line_no() {
  local pattern="$1"
  rg -n --fixed-strings -- "$pattern" "$WORKFLOW_FILE" | head -n 1 | cut -d: -f1
}

require_order() {
  local previous current current_label
  previous="$(line_no "$1")"
  if [ -z "$previous" ]; then
    echo "missing workflow line: $1" >&2
    exit 1
  fi

  shift
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

require_fixed 'name: Review Batch Checks'
require_fixed 'workflow_dispatch:'
require_fixed '      batches:'
require_fixed '        description: "Space-separated review batches to run. Leave empty for all."'
require_fixed '        default: ""'
require_fixed '        type: string'
require_fixed '      batch_timeout_seconds:'
require_fixed '        description: "Per-batch timeout passed to the review batch runner."'
require_fixed '        default: "0"'
require_fixed '        type: string'
require_fixed '      run_full_browser_ui_smoke:'
require_fixed '        description: "Also run the full Playwright browser smoke inside batch-3."'
require_fixed '        default: false'
require_fixed '        type: boolean'
require_fixed 'permissions:'
require_fixed '  contents: read'
require_fixed 'concurrency:'
require_fixed '  group: review-batch-checks'
require_fixed '  cancel-in-progress: false'

require_fixed '  plan-review-batches:'
require_fixed '    runs-on: ubuntu-latest'
require_fixed '      matrix: ${{ steps.plan.outputs.matrix }}'
require_fixed '      batches_text: ${{ steps.plan.outputs.batches_text }}'
require_fixed '      - name: Build review batch matrix'
require_fixed '      - name: Publish review batch selection'
require_fixed '## Review Batch Checks'

require_fixed '  run-review-batches:'
require_fixed '    needs: plan-review-batches'
require_fixed '      fail-fast: false'
require_fixed '      matrix: ${{ fromJson(needs.plan-review-batches.outputs.matrix) }}'
require_fixed '      BATCH_TIMEOUT_SECONDS: ${{ inputs.batch_timeout_seconds }}'
require_fixed "      RUN_FULL_BROWSER_UI_SMOKE: \${{ inputs.run_full_browser_ui_smoke && '1' || '0' }}"
require_fixed '      - name: Install facilitator dependencies'
require_fixed "        if: \${{ matrix.batch == 'batch-1' }}"
require_fixed '      - name: Install browser smoke dependencies'
require_fixed "        if: \${{ matrix.batch == 'batch-3' && inputs.run_full_browser_ui_smoke }}"
require_fixed '      - name: Run selected review batch'
require_fixed 'bash scripts/verify/run-review-batch-checks.sh "${{ matrix.batch }}"'

require_order \
  '      - name: Build review batch matrix' \
  '      - name: Publish review batch selection'

require_order \
  '      - uses: actions/checkout@v4' \
  '      - uses: actions/setup-node@v4' \
  '      - name: Install facilitator dependencies' \
  '      - name: Install browser smoke dependencies' \
  '      - name: Run selected review batch'

echo "review batch workflow contract smoke passed"
