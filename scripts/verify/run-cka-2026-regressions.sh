#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEFAULT_BASE_URL="${BASE_URL:-http://127.0.0.1:30080}"
SUITE_TIMEOUT_SECONDS="${SUITE_TIMEOUT_SECONDS:-2400}"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/verify/run-cka-2026-regressions.sh
  ./scripts/verify/run-cka-2026-regressions.sh cka-003
  ./scripts/verify/run-cka-2026-regressions.sh cka-004 cka-005
  ./scripts/verify/run-cka-2026-regressions.sh --list

Supported suites:
  cka-003  Dedicated dns-lab CoreDNS regression
  cka-004  Cluster-wide kube-system CoreDNS regression
  cka-005  Mixed-environment security/ingress/cluster-DNS regression

Notes:
  - The runner executes the selected suites sequentially.
  - Each suite restarts the local Podman stack and performs exam create/evaluate/cleanup.
  - You can override BASE_URL before running the script.
  - Set SUITE_TIMEOUT_SECONDS=0 to disable the per-suite timeout wrapper.
EOF
}

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

resolve_suite_script() {
  case "$1" in
    cka-003) printf '%s\n' "$ROOT_DIR/scripts/verify/cka-003-dedicated-dns-e2e.sh" ;;
    cka-004) printf '%s\n' "$ROOT_DIR/scripts/verify/cka-004-cluster-dns-e2e.sh" ;;
    cka-005) printf '%s\n' "$ROOT_DIR/scripts/verify/cka-005-isolated-env-e2e.sh" ;;
    *)
      echo "Unknown suite: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
}

run_suite() {
  local suite="$1"
  local script_path="$2"
  local started_at
  local elapsed
  local exit_code

  started_at="$(date +%s)"
  set +e
  if [ "$SUITE_TIMEOUT_SECONDS" -gt 0 ] && command -v timeout >/dev/null 2>&1; then
    BASE_URL="$DEFAULT_BASE_URL" timeout --foreground "${SUITE_TIMEOUT_SECONDS}s" bash "$script_path"
    exit_code=$?
  else
    BASE_URL="$DEFAULT_BASE_URL" bash "$script_path"
    exit_code=$?
  fi
  set -e

  elapsed="$(( $(date +%s) - started_at ))"

  if [ "$exit_code" -eq 0 ]; then
    log "${suite} regression completed successfully in ${elapsed}s"
    return 0
  fi

  if [ "$SUITE_TIMEOUT_SECONDS" -gt 0 ] && [ "$exit_code" -eq 124 ]; then
    log "${suite} regression timed out after ${SUITE_TIMEOUT_SECONDS}s"
  else
    log "${suite} regression failed after ${elapsed}s with exit code ${exit_code}"
  fi

  return "$exit_code"
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  usage
  exit 0
fi

if ! [[ "$SUITE_TIMEOUT_SECONDS" =~ ^[0-9]+$ ]]; then
  echo "SUITE_TIMEOUT_SECONDS must be a non-negative integer: $SUITE_TIMEOUT_SECONDS" >&2
  exit 1
fi

if [ "${1:-}" = "--list" ]; then
  printf '%s\n' cka-003 cka-004 cka-005
  exit 0
fi

SUITES=("$@")
if [ "${#SUITES[@]}" -eq 0 ]; then
  SUITES=(cka-003 cka-004 cka-005)
fi

for suite in "${SUITES[@]}"; do
  script_path="$(resolve_suite_script "$suite")"
  log "Running ${suite} regression via $(basename "$script_path")"
  run_suite "$suite" "$script_path"
done

log "Selected CKA 2026 regressions completed"
