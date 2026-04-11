#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

NOTES_DIR="$TMP_DIR/review-notes"
MEMOS_DIR="$TMP_DIR/review-memos"
NOTE_MANIFEST="$TMP_DIR/review-batch-note-manifest.txt"
MEMO_MANIFEST="$TMP_DIR/review-batch-memo-manifest.txt"
OUTPUT_DIR="$TMP_DIR/review-handoff"
ARCHIVE_PATH="$TMP_DIR/review-handoff.tar.gz"

mkdir -p "$NOTES_DIR" "$MEMOS_DIR"

cat > "$NOTES_DIR/batch-2-bounded-wait-guards.txt" <<'EOF'
batch-2 | note-subset=tracked-modified | name=bounded-wait-guards | file-count=1 | note-point-count=3
batch-2 | NOTE | tracked-modified | name=bounded-wait-guards | file=scripts/verify/cka-005-isolated-env-e2e.sh | lines=7-129 | focus=retry budgets and bounded wait helpers
EOF

cat > "$MEMOS_DIR/batch-2-tracked-modified-memo.txt" <<'EOF'
batch-2 | memo-subset=tracked-modified | file-count=1 | section-count=1 | point-count=3
batch-2 | MEMO-SECTION | tracked-modified | name=bounded-wait-guards | file=scripts/verify/cka-005-isolated-env-e2e.sh | lines=7-129 | focus=retry budgets and bounded wait helpers
EOF

printf '%s\n' \
  "2026-04-11T18:00:00+09:00 | batches=batch-2 | filter=tracked-modified | name=bounded-wait-guards | output=$NOTES_DIR/batch-2-bounded-wait-guards.txt | bytes=$(wc -c < "$NOTES_DIR/batch-2-bounded-wait-guards.txt" | tr -d '[:space:]')" \
  > "$NOTE_MANIFEST"

printf '%s\n' \
  "2026-04-11T18:00:10+09:00 | batches=batch-2 | filter=tracked-modified | output=$MEMOS_DIR/batch-2-tracked-modified-memo.txt | bytes=$(wc -c < "$MEMOS_DIR/batch-2-tracked-modified-memo.txt" | tr -d '[:space:]')" \
  > "$MEMO_MANIFEST"

NOTE_MANIFEST_PATH="$NOTE_MANIFEST" \
MEMO_MANIFEST_PATH="$MEMO_MANIFEST" \
REVIEW_NOTES_DIR="$NOTES_DIR" \
REVIEW_MEMOS_DIR="$MEMOS_DIR" \
bash "$ROOT_DIR/scripts/verify/pack-review-batch-handoff.sh" "$OUTPUT_DIR" "$ARCHIVE_PATH" >/dev/null

[ -f "$OUTPUT_DIR/handoff-index.txt" ]
[ -f "$OUTPUT_DIR/landing-plan.txt" ]
[ -f "$OUTPUT_DIR/landing-plan-expanded.txt" ]
[ -f "$OUTPUT_DIR/landing-summary.md" ]
[ -f "$OUTPUT_DIR/landing-drafts.md" ]
[ -f "$OUTPUT_DIR/status-all.txt" ]
[ -f "$OUTPUT_DIR/next.txt" ]
[ -f "$OUTPUT_DIR/next-verbose.txt" ]
[ -f "$OUTPUT_DIR/note-manifest-report.txt" ]
[ -f "$OUTPUT_DIR/memo-manifest-report.txt" ]
[ -f "$OUTPUT_DIR/review-batch-note-manifest.txt" ]
[ -f "$OUTPUT_DIR/review-batch-memo-manifest.txt" ]
[ -f "$OUTPUT_DIR/review-notes/batch-2-bounded-wait-guards.txt" ]
[ -f "$OUTPUT_DIR/review-memos/batch-2-tracked-modified-memo.txt" ]
[ -f "$ARCHIVE_PATH" ]

grep -Eq '^HANDOFF-INDEX \| note-manifest=.+' "$OUTPUT_DIR/handoff-index.txt"
grep -Eq '^LANDING-PLAN \| batches=[0-9]+$' "$OUTPUT_DIR/landing-plan.txt"
grep -Eq '^LANDING-PLAN \| batches=[0-9]+$' "$OUTPUT_DIR/landing-plan-expanded.txt"
grep -Eq '^batch-2 \| LANDING-STEP \| order=2 \| landing-state=[a-z-]+ \| readiness=[a-z-]+ \| handoff=[a-z-]+ \| artifact-state=[a-z-]+ \| commit-scope=cka-regressions-and-diagnostics \| files=[0-9]+ \| tracked-modified=[0-9]+ \| untracked=[0-9]+ \| missing=[0-9]+$' "$OUTPUT_DIR/landing-plan.txt"
grep -Eq '^batch-2 \| LANDING-FILE \| tracked-modified \| scripts/verify/cka-005-isolated-env-e2e\.sh$' "$OUTPUT_DIR/landing-plan-expanded.txt"
grep -Eq '^## Review Landing Summary$' "$OUTPUT_DIR/landing-summary.md"
grep -Eq '^\*\*Verdict: [A-Z -]+\*\* ' "$OUTPUT_DIR/landing-summary.md"
grep -Eq '^2\. \*\*batch-2\*\* `cka-regressions-and-diagnostics`$' "$OUTPUT_DIR/landing-summary.md"
grep -Eq '^   Latest artifacts: note `.+`; memo `.+`$' "$OUTPUT_DIR/landing-summary.md"
grep -Eq '^## Review Landing Drafts$' "$OUTPUT_DIR/landing-drafts.md"
grep -Eq '^### batch-2$' "$OUTPUT_DIR/landing-drafts.md"
grep -Eq '^- Commit title: `chore\(review\): land cka-regressions-and-diagnostics batch`$' "$OUTPUT_DIR/landing-drafts.md"
grep -Eq '^- PR title: `Land batch-2 \(cka-regressions-and-diagnostics\) handoff bundle`$' "$OUTPUT_DIR/landing-drafts.md"
grep -Eq '^batch-2 \| HANDOFF-ARTIFACTS \| artifact-state=' "$OUTPUT_DIR/handoff-index.txt"
grep -Eq '^NOTE-MANIFEST \| path=.+' "$OUTPUT_DIR/note-manifest-report.txt"
grep -Eq '^MEMO-MANIFEST \| path=.+' "$OUTPUT_DIR/memo-manifest-report.txt"
grep -Eq '^echo no-pending-review-actions$|^\./scripts/verify/run-review-batch-checks\.sh .+$' "$OUTPUT_DIR/next.txt"
grep -Eq '^NEXT \|' "$OUTPUT_DIR/next-verbose.txt"

tar -tzf "$ARCHIVE_PATH" | grep -Fx 'review-handoff/handoff-index.txt' >/dev/null
tar -tzf "$ARCHIVE_PATH" | grep -Fx 'review-handoff/landing-plan.txt' >/dev/null
tar -tzf "$ARCHIVE_PATH" | grep -Fx 'review-handoff/landing-plan-expanded.txt' >/dev/null
tar -tzf "$ARCHIVE_PATH" | grep -Fx 'review-handoff/landing-summary.md' >/dev/null
tar -tzf "$ARCHIVE_PATH" | grep -Fx 'review-handoff/landing-drafts.md' >/dev/null
tar -tzf "$ARCHIVE_PATH" | grep -Fx 'review-handoff/review-notes/batch-2-bounded-wait-guards.txt' >/dev/null
tar -tzf "$ARCHIVE_PATH" | grep -Fx 'review-handoff/review-memos/batch-2-tracked-modified-memo.txt' >/dev/null

echo "review batch handoff pack smoke passed"
