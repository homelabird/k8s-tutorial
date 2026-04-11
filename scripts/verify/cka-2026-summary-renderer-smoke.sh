#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RENDERER="$ROOT_DIR/scripts/verify/render-cka-2026-summary-markdown.sh"
TMP_DIR="$(mktemp -d)"
SUMMARY_FILE="$TMP_DIR/summary.txt"

cleanup() {
  rm -rf "$TMP_DIR"
}

trap cleanup EXIT

cat >"$SUMMARY_FILE" <<'EOF'
CKA 2026 Diagnostics Summary
Generated: 2026-04-10 21:00:00
Base URL: http://127.0.0.1:30080
Current exam HTTP status: 500
Current exam ID: fixture-exam
Summary exam ID: fixture-exam
Summary suite ID: cka-fixture
Recent exam IDs: fixture-exam
Evaluation attempts: 1
Last evaluation score: 33%
Evaluation score history: 33%
Overall health: unrecovered failures remain
Latest facilitator lifecycle event: 2026-04-10 20:59:59 [error]: Fixture evaluation failed

Read next:
  1. facilitator-exam-lifecycle.log
  2. jumphost-west-orchestration.log
  3. jumphost-east-orchestration.log
  4. podman-compose.log
  5. facilitator.clean.log

Question summary:
  q1: 0 passed / 1 failed, latest attempt FAILED, last failure q1/v1 - cluster api unavailable, recovery unrecovered
  q2: 1 passed / 1 failed, latest attempt PASSED, last failure q2/v2 - dns restore lag, recovery 2026-04-10 20:59:40 -> 2026-04-10 20:59:52 (12s)

Host: jumphost-west
  prepare-exam-env exitCode: 0
  verification events: 0 passed / 1 failed
  last failed verification: q1/v1 - cluster api unavailable
  recovery: unrecovered
  cleanup-exam-env exitCode: 1

Host: jumphost-east
  prepare-exam-env exitCode: 0
  verification events: 1 passed / 1 failed
  last failed verification: q2/v2 - dns restore lag
  recovery: 2026-04-10 20:59:40 -> 2026-04-10 20:59:52 (12s)
  cleanup-exam-env exitCode: 0

Host: jumphost
  prepare-exam-env exitCode: 0
  verification events: 2 passed / 0 failed
  last failed verification: none
  recovery: none
  cleanup-exam-env exitCode: 0

Key files:
  summary.txt
  facilitator-exam-lifecycle.log
  jumphost-west-orchestration.log
  jumphost-east-orchestration.log
  jumphost-orchestration.log
  facilitator.clean.log
  podman-compose.log
  current-exam.json
EOF

OUTPUT="$(bash "$RENDERER" "$SUMMARY_FILE")"

grep -Fq '1. `facilitator-exam-lifecycle.log`' <<<"$OUTPUT"
grep -Fq '2. `jumphost-west-orchestration.log`' <<<"$OUTPUT"
grep -Fq '3. `jumphost-east-orchestration.log`' <<<"$OUTPUT"
grep -Fq '**FAILED** cause `cluster api unavailable` `jumphost-west`' <<<"$OUTPUT"
grep -Fq '**RECOVERED** recovery `12s` `jumphost-east`' <<<"$OUTPUT"
grep -Fq '<summary>Passing hosts (1)</summary>' <<<"$OUTPUT"

echo "cka-2026 summary renderer smoke passed"
