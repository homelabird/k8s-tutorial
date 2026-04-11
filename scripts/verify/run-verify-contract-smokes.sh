#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SMOKE_TIMEOUT_SECONDS="${SMOKE_TIMEOUT_SECONDS:-0}"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/verify/run-verify-contract-smokes.sh
  ./scripts/verify/run-verify-contract-smokes.sh diagnostics-collector diagnostics-pack
  ./scripts/verify/run-verify-contract-smokes.sh browser-scenarios workflow-contract review-batch-workflow review-handoff-pack
  ./scripts/verify/run-verify-contract-smokes.sh --list
  ./scripts/verify/run-verify-contract-smokes.sh --describe

Supported contract smokes:
  diagnostics-collector  Synthetic raw diagnostics bundle generation
  diagnostics-pack       Synthetic diagnostics archive + summary round-trip
  summary-renderer       Synthetic markdown summary rendering
  workflow-contract      Self-hosted workflow wiring contract
  review-batch-workflow  Review-batch workflow wiring contract
  review-handoff-pack    Review handoff export and archive contract
  browser-scenarios      Browser smoke scenario inventory contract

Notes:
  - The runner executes the selected contract smokes sequentially.
  - These are lightweight checks and do not require the full Podman stack.
  - Set SMOKE_TIMEOUT_SECONDS=0 to disable per-smoke timeout wrapping.
EOF
}

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

resolve_smoke_script() {
  case "$1" in
    diagnostics-collector) printf '%s\n' "$ROOT_DIR/scripts/verify/cka-2026-diagnostics-collector-smoke.sh" ;;
    diagnostics-pack) printf '%s\n' "$ROOT_DIR/scripts/verify/cka-2026-diagnostics-pack-smoke.sh" ;;
    summary-renderer) printf '%s\n' "$ROOT_DIR/scripts/verify/cka-2026-summary-renderer-smoke.sh" ;;
    workflow-contract) printf '%s\n' "$ROOT_DIR/scripts/verify/cka-2026-workflow-contract-smoke.sh" ;;
    review-batch-workflow) printf '%s\n' "$ROOT_DIR/scripts/verify/review-batch-workflow-contract-smoke.sh" ;;
    review-handoff-pack) printf '%s\n' "$ROOT_DIR/scripts/verify/review-batch-handoff-pack-smoke.sh" ;;
    browser-scenarios) printf '%s\n' "$ROOT_DIR/scripts/verify/browser-ui-scenario-contract-smoke.sh" ;;
    *)
      echo "Unknown contract smoke: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
}

describe_smoke() {
  case "$1" in
    diagnostics-collector)
      printf '%s\n' 'diagnostics-collector | cka-2026-diagnostics-collector-smoke.sh | raw diagnostics bundle generation, host discovery, summary.txt'
      ;;
    diagnostics-pack)
      printf '%s\n' 'diagnostics-pack | cka-2026-diagnostics-pack-smoke.sh | tarball packaging and extracted summary round-trip'
      ;;
    summary-renderer)
      printf '%s\n' 'summary-renderer | cka-2026-summary-renderer-smoke.sh | markdown rendering, host ordering, verdict-aware summary sections'
      ;;
    workflow-contract)
      printf '%s\n' 'workflow-contract | cka-2026-workflow-contract-smoke.sh | self-hosted workflow inputs, guards, artifact and summary publication'
      ;;
    review-batch-workflow)
      printf '%s\n' 'review-batch-workflow | review-batch-workflow-contract-smoke.sh | manual review batch workflow inputs, matrix planning, dependency gates'
      ;;
    review-handoff-pack)
      printf '%s\n' 'review-handoff-pack | review-batch-handoff-pack-smoke.sh | review note/memo manifest export, landing summary, landing drafts, handoff index, and archive contents'
      ;;
    browser-scenarios)
      printf '%s\n' 'browser-scenarios | browser-ui-scenario-contract-smoke.sh | browser fixture scenario inventory, package wiring, README alignment'
      ;;
    *)
      echo "Unknown contract smoke: $1" >&2
      exit 1
      ;;
  esac
}

run_smoke() {
  local smoke="$1"
  local script_path="$2"
  local started_at elapsed exit_code

  started_at="$(date +%s)"
  set +e
  if [ "$SMOKE_TIMEOUT_SECONDS" -gt 0 ] && command -v timeout >/dev/null 2>&1; then
    timeout --foreground "${SMOKE_TIMEOUT_SECONDS}s" bash "$script_path"
    exit_code=$?
  else
    bash "$script_path"
    exit_code=$?
  fi
  set -e

  elapsed="$(( $(date +%s) - started_at ))"

  if [ "$exit_code" -eq 0 ]; then
    log "${smoke} contract smoke completed successfully in ${elapsed}s"
    return 0
  fi

  if [ "$SMOKE_TIMEOUT_SECONDS" -gt 0 ] && [ "$exit_code" -eq 124 ]; then
    log "${smoke} contract smoke timed out after ${SMOKE_TIMEOUT_SECONDS}s"
  else
    log "${smoke} contract smoke failed after ${elapsed}s with exit code ${exit_code}"
  fi

  return "$exit_code"
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  usage
  exit 0
fi

if ! [[ "$SMOKE_TIMEOUT_SECONDS" =~ ^[0-9]+$ ]]; then
  echo "SMOKE_TIMEOUT_SECONDS must be a non-negative integer: $SMOKE_TIMEOUT_SECONDS" >&2
  exit 1
fi

if [ "${1:-}" = "--list" ]; then
  printf '%s\n' \
    diagnostics-collector \
    diagnostics-pack \
    summary-renderer \
    workflow-contract \
    review-batch-workflow \
    review-handoff-pack \
    browser-scenarios
  exit 0
fi

if [ "${1:-}" = "--describe" ]; then
  for smoke in \
    diagnostics-collector \
    diagnostics-pack \
    summary-renderer \
    workflow-contract \
    review-batch-workflow \
    review-handoff-pack \
    browser-scenarios; do
    describe_smoke "$smoke"
  done
  exit 0
fi

SMOKES=("$@")
if [ "${#SMOKES[@]}" -eq 0 ]; then
  SMOKES=(
    diagnostics-collector
    diagnostics-pack
    summary-renderer
    workflow-contract
    review-batch-workflow
    review-handoff-pack
    browser-scenarios
  )
fi

for smoke in "${SMOKES[@]}"; do
  script_path="$(resolve_smoke_script "$smoke")"
  log "Running ${smoke} contract smoke via $(basename "$script_path")"
  run_smoke "$smoke" "$script_path"
done

log "Selected contract smokes completed"
