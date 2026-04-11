#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

NOTES_DIR="$TMP_DIR/review-notes"
MEMOS_DIR="$TMP_DIR/review-memos"
DRAFTS_DIR="$TMP_DIR/review-drafts"
NOTE_MANIFEST="$TMP_DIR/review-batch-note-manifest.txt"
MEMO_MANIFEST="$TMP_DIR/review-batch-memo-manifest.txt"
DRAFT_MANIFEST="$TMP_DIR/review-draft-manifest.txt"
OUTPUT_DIR="$TMP_DIR/review-handoff"
ARCHIVE_PATH="$TMP_DIR/review-handoff.tar.gz"

mkdir -p "$NOTES_DIR" "$MEMOS_DIR" "$DRAFTS_DIR"

cat > "$NOTES_DIR/batch-2-bounded-wait-guards.txt" <<'EOF'
batch-2 | note-subset=tracked-modified | name=bounded-wait-guards | file-count=1 | note-point-count=3
batch-2 | NOTE | tracked-modified | name=bounded-wait-guards | file=scripts/verify/cka-005-isolated-env-e2e.sh | lines=7-129 | focus=retry budgets and bounded wait helpers
EOF

cat > "$MEMOS_DIR/batch-2-tracked-modified-memo.txt" <<'EOF'
batch-2 | memo-subset=tracked-modified | file-count=1 | section-count=1 | point-count=3
batch-2 | MEMO-SECTION | tracked-modified | name=bounded-wait-guards | file=scripts/verify/cka-005-isolated-env-e2e.sh | lines=7-129 | focus=retry budgets and bounded wait helpers
EOF

cat > "$DRAFTS_DIR/outside-frontend-runtime.md" <<'EOF'
## outside-frontend-runtime

- Commit title: `chore(review): land outside-frontend-runtime batch`
- PR title: `Land outside-frontend-runtime handoff bundle`
EOF

printf '%s\n' \
  "2026-04-11T18:00:00+09:00 | batches=batch-2 | filter=tracked-modified | name=bounded-wait-guards | output=$NOTES_DIR/batch-2-bounded-wait-guards.txt | bytes=$(wc -c < "$NOTES_DIR/batch-2-bounded-wait-guards.txt" | tr -d '[:space:]')" \
  > "$NOTE_MANIFEST"

printf '%s\n' \
  "2026-04-11T18:00:10+09:00 | batches=batch-2 | filter=tracked-modified | output=$MEMOS_DIR/batch-2-tracked-modified-memo.txt | bytes=$(wc -c < "$MEMOS_DIR/batch-2-tracked-modified-memo.txt" | tr -d '[:space:]')" \
  > "$MEMO_MANIFEST"

printf '%s\n' \
  "2026-04-11T18:00:20+09:00 | batches=outside-batches | filter=outside-landing-draft | name=outside-frontend-runtime | output=$DRAFTS_DIR/outside-frontend-runtime.md | bytes=$(wc -c < "$DRAFTS_DIR/outside-frontend-runtime.md" | tr -d '[:space:]')" \
  > "$DRAFT_MANIFEST"

NOTE_MANIFEST_PATH="$NOTE_MANIFEST" \
MEMO_MANIFEST_PATH="$MEMO_MANIFEST" \
OUTSIDE_LANDING_DRAFT_MANIFEST_PATH="$DRAFT_MANIFEST" \
REVIEW_NOTES_DIR="$NOTES_DIR" \
REVIEW_MEMOS_DIR="$MEMOS_DIR" \
REVIEW_DRAFTS_DIR="$DRAFTS_DIR" \
bash "$ROOT_DIR/scripts/verify/pack-review-batch-handoff.sh" "$OUTPUT_DIR" "$ARCHIVE_PATH" >/dev/null

[ -f "$OUTPUT_DIR/handoff-index.txt" ]
[ -f "$OUTPUT_DIR/landing-plan.txt" ]
[ -f "$OUTPUT_DIR/landing-plan-expanded.txt" ]
[ -f "$OUTPUT_DIR/landing-commands.txt" ]
[ -f "$OUTPUT_DIR/outside-batch-plan.txt" ]
[ -f "$OUTPUT_DIR/outside-batch-plan-expanded.txt" ]
[ -f "$OUTPUT_DIR/outside-landing-batches.txt" ]
[ -f "$OUTPUT_DIR/outside-landing-batches-expanded.txt" ]
[ -f "$OUTPUT_DIR/landing-summary.md" ]
[ -f "$OUTPUT_DIR/landing-drafts.md" ]
[ -f "$OUTPUT_DIR/status-all.txt" ]
[ -f "$OUTPUT_DIR/next.txt" ]
[ -f "$OUTPUT_DIR/next-verbose.txt" ]
[ -f "$OUTPUT_DIR/note-manifest-report.txt" ]
[ -f "$OUTPUT_DIR/memo-manifest-report.txt" ]
[ -f "$OUTPUT_DIR/review-batch-note-manifest.txt" ]
[ -f "$OUTPUT_DIR/review-batch-memo-manifest.txt" ]
[ -f "$OUTPUT_DIR/review-draft-manifest.txt" ]
[ -f "$OUTPUT_DIR/review-notes/batch-2-bounded-wait-guards.txt" ]
[ -f "$OUTPUT_DIR/review-memos/batch-2-tracked-modified-memo.txt" ]
[ -f "$OUTPUT_DIR/review-drafts/outside-frontend-runtime.md" ]
[ -f "$ARCHIVE_PATH" ]

grep -Eq '^HANDOFF-INDEX \| note-manifest=.+' "$OUTPUT_DIR/handoff-index.txt"
grep -Eq '^HANDOFF-INDEX \| note-manifest=.+ \| memo-manifest=.+ \| batches=[0-9]+ \| outside-batches=[01]$' "$OUTPUT_DIR/handoff-index.txt"
grep -Eq '^LANDING-PLAN \| batches=[0-9]+$' "$OUTPUT_DIR/landing-plan.txt"
grep -Eq '^LANDING-PLAN \| batches=[0-9]+$' "$OUTPUT_DIR/landing-plan-expanded.txt"
grep -Eq '^(batch-[0-9]+|outside-[a-z0-9-]+) \| LANDING-COMMAND-STEP \| state=(actionable|noop|pending-handoff|blocked) \| landing-state=[a-z-]+' "$OUTPUT_DIR/landing-commands.txt"
grep -Eq '^(batch-[0-9]+|outside-[a-z0-9-]+) \| LANDING-COMMAND \| type=(stage|commit|commit-title|pr-title|next) \|' "$OUTPUT_DIR/landing-commands.txt"
grep -Eq '^LANDING-COMMANDS \| steps=[0-9]+ \| actionable=[0-9]+ \| noop=[0-9]+ \| pending-handoff=[0-9]+ \| blocked=[0-9]+$' "$OUTPUT_DIR/landing-commands.txt"
grep -Eq '^OUTSIDE-LANDING-SUMMARY \| groups=[0-9]+ \| total=[0-9]+ \| matched-files=[0-9]+ \| unmatched-files=[0-9]+$' "$OUTPUT_DIR/outside-batch-plan.txt"
grep -Eq '^OUTSIDE-LANDING-SUMMARY \| groups=[0-9]+ \| total=[0-9]+ \| matched-files=[0-9]+ \| unmatched-files=[0-9]+$' "$OUTPUT_DIR/outside-batch-plan-expanded.txt"
grep -Eq '^LANDING-PLAN \| batches=[0-9]+$' "$OUTPUT_DIR/outside-landing-batches.txt"
grep -Eq '^LANDING-PLAN \| batches=[0-9]+$' "$OUTPUT_DIR/outside-landing-batches-expanded.txt"
grep -Eq '^batch-2 \| LANDING-STEP \| order=2 \| landing-state=[a-z-]+ \| readiness=[a-z-]+ \| handoff=[a-z-]+ \| artifact-state=[a-z-]+ \| commit-scope=cka-regressions-and-diagnostics \| files=[0-9]+ \| tracked-modified=[0-9]+ \| untracked=[0-9]+ \| missing=[0-9]+$' "$OUTPUT_DIR/landing-plan.txt"
grep -Eq '^batch-2 \| LANDING-FILE \| tracked-modified \| .+$' "$OUTPUT_DIR/landing-plan-expanded.txt"
grep -Eq '^## Review Landing Summary$' "$OUTPUT_DIR/landing-summary.md"
grep -Eq '^\*\*Verdict: [A-Z -]+\*\* ' "$OUTPUT_DIR/landing-summary.md"
grep -Eq '^- Landing command source: `.+landing-commands\.txt`$' "$OUTPUT_DIR/landing-summary.md"
grep -Eq '^### Next Landing Command$' "$OUTPUT_DIR/landing-summary.md"
if grep -Eq '^- Target: \*\*(batch-[0-9]+|outside-[a-z0-9-]+)\*\* `.+`$' "$OUTPUT_DIR/landing-summary.md"; then
  grep -Eq '^- Stage: `.+`$' "$OUTPUT_DIR/landing-summary.md"
  grep -Eq '^- Commit: `.+`$' "$OUTPUT_DIR/landing-summary.md"
else
  grep -Eq '^- Pending target: \*\*(batch-[0-9]+|outside-[a-z0-9-]+)\*\* `.+`$' "$OUTPUT_DIR/landing-summary.md"
  grep -Eq '^- Next handoff: `.+`$' "$OUTPUT_DIR/landing-summary.md"
fi
grep -Eq '^2\. \*\*batch-2\*\* `cka-regressions-and-diagnostics`$' "$OUTPUT_DIR/landing-summary.md"
grep -Eq '^   Latest artifacts: note `.+`; memo `.+`$' "$OUTPUT_DIR/landing-summary.md"
grep -Eq '^## Review Landing Drafts$' "$OUTPUT_DIR/landing-drafts.md"
grep -Eq '^### batch-2$' "$OUTPUT_DIR/landing-drafts.md"
grep -Eq '^- Commit title: `chore\(review\): land cka-regressions-and-diagnostics batch`$' "$OUTPUT_DIR/landing-drafts.md"
grep -Eq '^- PR title: `Land batch-2 \(cka-regressions-and-diagnostics\) handoff bundle`$' "$OUTPUT_DIR/landing-drafts.md"
grep -Eq '^Suggested shell commands:$' "$OUTPUT_DIR/landing-drafts.md"
grep -Eq '^(git add -- .+|git commit -m .+|\./scripts/verify/run-review-batch-checks\.sh .+|echo no-files-to-stage)$' "$OUTPUT_DIR/landing-drafts.md"
grep -Eq '^batch-2 \| HANDOFF-ARTIFACTS \| artifact-state=' "$OUTPUT_DIR/handoff-index.txt"
if grep -Eq '\| outside-batches=1$' "$OUTPUT_DIR/handoff-index.txt"; then
  grep -Eq '^outside-batches \| HANDOFF-ARTIFACTS \| artifact-state=' "$OUTPUT_DIR/handoff-index.txt"
fi
grep -Eq '^NOTE-MANIFEST \| path=.+' "$OUTPUT_DIR/note-manifest-report.txt"
grep -Eq '^MEMO-MANIFEST \| path=.+' "$OUTPUT_DIR/memo-manifest-report.txt"
grep -Eq '^2026-04-11T18:00:20\+09:00 \| batches=outside-batches \| filter=outside-landing-draft \| name=outside-frontend-runtime \| output=.+' "$OUTPUT_DIR/review-draft-manifest.txt"
grep -Eq '^echo no-pending-review-actions$|^\./scripts/verify/run-review-batch-checks\.sh .+$' "$OUTPUT_DIR/next.txt"
grep -Eq '^NEXT \|' "$OUTPUT_DIR/next-verbose.txt"

OUTSIDE_LANDING_BATCHES="$(awk -F'batches=' '/^LANDING-PLAN \| batches=/{print $2; exit}' "$OUTPUT_DIR/outside-landing-batches.txt" | tr -d '[:space:]')"
if [ -z "$OUTSIDE_LANDING_BATCHES" ]; then
  echo "Failed to parse outside landing batch count" >&2
  exit 1
fi

if [ "$OUTSIDE_LANDING_BATCHES" -gt 0 ]; then
  grep -Eq '^outside-[a-z0-9-]+ \| LANDING-STEP \| order=[0-9]+ \| landing-state=[a-z-]+ \| readiness=needs-landing \| handoff=[a-z-]+ \| artifact-state=[a-z-]+ \| commit-scope=outside-[a-z0-9-]+ \| focus=.+ \| files=[0-9]+ \| tracked-modified=[0-9]+ \| untracked=[0-9]+ \| missing=0$' "$OUTPUT_DIR/outside-landing-batches.txt"
  grep -Eq '^outside-[a-z0-9-]+ \| LANDING-HANDOFF \| next=.+$' "$OUTPUT_DIR/outside-landing-batches-expanded.txt"
  grep -Eq '^outside-[a-z0-9-]+ \| LANDING-ARTIFACT \| type=latest-memo \| path=\.artifacts/review-memos/outside-batches-outside-batch-memo\.txt$' "$OUTPUT_DIR/outside-landing-batches-expanded.txt"
  grep -Eq '^### Outside Landing Order$' "$OUTPUT_DIR/landing-summary.md"
  grep -Eq '^Grouped memo: `\.artifacts/review-memos/outside-batches-outside-batch-memo\.txt`$' "$OUTPUT_DIR/landing-summary.md"
  grep -Eq '^[0-9]+\. \*\*outside-[a-z0-9-]+\*\* focus `.+`$' "$OUTPUT_DIR/landing-summary.md"
  grep -Eq '^## Outside Landing Drafts$' "$OUTPUT_DIR/landing-drafts.md"
  grep -Eq '^### outside-[a-z0-9-]+$' "$OUTPUT_DIR/landing-drafts.md"
  grep -Eq '^- Grouped memo: `\.artifacts/review-memos/outside-batches-outside-batch-memo\.txt`$' "$OUTPUT_DIR/landing-drafts.md"
else
  ! grep -Eq '^outside-[a-z0-9-]+ \| LANDING-STEP \| ' "$OUTPUT_DIR/outside-landing-batches.txt"
  ! grep -Eq '^outside-[a-z0-9-]+ \| LANDING-HANDOFF \| ' "$OUTPUT_DIR/outside-landing-batches-expanded.txt"
  ! grep -Eq '^outside-[a-z0-9-]+ \| LANDING-ARTIFACT \| ' "$OUTPUT_DIR/outside-landing-batches-expanded.txt"
  ! grep -Eq '^### Outside Landing Order$' "$OUTPUT_DIR/landing-summary.md"
  ! grep -Eq '^## Outside Landing Drafts$' "$OUTPUT_DIR/landing-drafts.md"
fi

tar -tzf "$ARCHIVE_PATH" | grep -Fx 'review-handoff/handoff-index.txt' >/dev/null
tar -tzf "$ARCHIVE_PATH" | grep -Fx 'review-handoff/landing-plan.txt' >/dev/null
tar -tzf "$ARCHIVE_PATH" | grep -Fx 'review-handoff/landing-plan-expanded.txt' >/dev/null
tar -tzf "$ARCHIVE_PATH" | grep -Fx 'review-handoff/landing-commands.txt' >/dev/null
tar -tzf "$ARCHIVE_PATH" | grep -Fx 'review-handoff/outside-batch-plan.txt' >/dev/null
tar -tzf "$ARCHIVE_PATH" | grep -Fx 'review-handoff/outside-batch-plan-expanded.txt' >/dev/null
tar -tzf "$ARCHIVE_PATH" | grep -Fx 'review-handoff/outside-landing-batches.txt' >/dev/null
tar -tzf "$ARCHIVE_PATH" | grep -Fx 'review-handoff/outside-landing-batches-expanded.txt' >/dev/null
tar -tzf "$ARCHIVE_PATH" | grep -Fx 'review-handoff/landing-summary.md' >/dev/null
tar -tzf "$ARCHIVE_PATH" | grep -Fx 'review-handoff/landing-drafts.md' >/dev/null
tar -tzf "$ARCHIVE_PATH" | grep -Fx 'review-handoff/review-notes/batch-2-bounded-wait-guards.txt' >/dev/null
tar -tzf "$ARCHIVE_PATH" | grep -Fx 'review-handoff/review-memos/batch-2-tracked-modified-memo.txt' >/dev/null
tar -tzf "$ARCHIVE_PATH" | grep -Fx 'review-handoff/review-drafts/outside-frontend-runtime.md' >/dev/null

echo "review batch handoff pack smoke passed"
