#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PACKER="$ROOT_DIR/scripts/verify/pack-cka-2026-diagnostics.sh"
RENDERER="$ROOT_DIR/scripts/verify/render-cka-2026-summary-markdown.sh"
ARTIFACT_ROOT="$ROOT_DIR/.artifacts"
mkdir -p "$ARTIFACT_ROOT"
WORK_DIR="$(mktemp -d "$ARTIFACT_ROOT/pack-smoke.XXXXXX")"
WORK_DIR_REL="${WORK_DIR#"$ROOT_DIR/"}"
OUTPUT_DIR="$WORK_DIR/bundle"
OUTPUT_DIR_REL="$WORK_DIR_REL/bundle"
ARCHIVE_PATH="$WORK_DIR/bundle.tar.gz"
ARCHIVE_PATH_REL="$WORK_DIR_REL/bundle.tar.gz"
EXTRACT_DIR="$WORK_DIR/extracted"

cleanup() {
  rm -rf "$WORK_DIR"
}

trap cleanup EXIT

mkdir -p "$OUTPUT_DIR"

cat >"$OUTPUT_DIR/summary.txt" <<'EOF'
CKA 2026 Diagnostics Summary
Summary suite ID: cka-fixture
Overall health: recovery verified after initial failures

Host: dns-east
  recovery: 2026-04-10 21:00:15 -> 2026-04-10 21:00:22 (7s)
EOF

cat >"$OUTPUT_DIR/facilitator-exam-lifecycle.log" <<'EOF'
2026-04-10 21:00:10 [info]: Received request to evaluate exam {"examId":"11111111-1111-4111-8111-111111111111","service":"facilitator-service"}
EOF

cat >"$OUTPUT_DIR/dns-east-orchestration.log" <<'EOF'
2026-04-10 21:00:15 [info]: Verification 2 for question 2: FAILED {"host":"dns-east","stdout":"dns restore lag","service":"facilitator-service"}
EOF

cat >"$OUTPUT_DIR/summary-hosts.txt" <<'EOF'
dns-east
EOF

cat >"$OUTPUT_DIR/current-exam.json" <<'EOF'
{"error":"no current exam"}
EOF

SKIP_COLLECT=1 bash "$PACKER" "$OUTPUT_DIR_REL" "$ARCHIVE_PATH_REL"

[ -f "$ARCHIVE_PATH" ]

archive_listing="$(tar -tzf "$ARCHIVE_PATH")"
grep -Fq 'summary.txt' <<<"$archive_listing"
grep -Fq 'facilitator-exam-lifecycle.log' <<<"$archive_listing"
grep -Fq 'dns-east-orchestration.log' <<<"$archive_listing"
grep -Fq 'summary-hosts.txt' <<<"$archive_listing"
grep -Fq 'current-exam.json' <<<"$archive_listing"

archive_summary="$(tar -xOf "$ARCHIVE_PATH" "$OUTPUT_DIR_REL/summary.txt")"
grep -Fq 'Summary suite ID: cka-fixture' <<<"$archive_summary"
grep -Fq 'Overall health: recovery verified after initial failures' <<<"$archive_summary"

mkdir -p "$EXTRACT_DIR"
tar -xzf "$ARCHIVE_PATH" -C "$EXTRACT_DIR"
rendered_summary="$(bash "$RENDERER" "$EXTRACT_DIR/$OUTPUT_DIR_REL/summary.txt")"
grep -Fq '**Verdict: RECOVERED** recovery verified after initial failures' <<<"$rendered_summary"
grep -Fq '`dns-east`' <<<"$rendered_summary"
grep -Fq '`dns-east-orchestration.log`' <<<"$rendered_summary"

echo "cka-2026 diagnostics pack smoke passed"
