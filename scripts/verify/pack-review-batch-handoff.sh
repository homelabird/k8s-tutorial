#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUTPUT_DIR="${1:-$ROOT_DIR/.artifacts/review-handoff}"
ARCHIVE_PATH="${2:-$ROOT_DIR/.artifacts/review-handoff.tar.gz}"
RUNNER="$ROOT_DIR/scripts/verify/run-review-batch-checks.sh"
LANDING_RENDERER="$ROOT_DIR/scripts/verify/render-review-landing-summary.sh"
LANDING_DRAFT_RENDERER="$ROOT_DIR/scripts/verify/render-review-landing-drafts.sh"
NOTE_MANIFEST="${NOTE_MANIFEST_PATH:-$ROOT_DIR/.artifacts/review-batch-note-manifest.txt}"
MEMO_MANIFEST="${MEMO_MANIFEST_PATH:-$ROOT_DIR/.artifacts/review-batch-memo-manifest.txt}"
REVIEW_NOTES_DIR="${REVIEW_NOTES_DIR:-$ROOT_DIR/.artifacts/review-notes}"
REVIEW_MEMOS_DIR="${REVIEW_MEMOS_DIR:-$ROOT_DIR/.artifacts/review-memos}"

export NOTE_MANIFEST_PATH="$NOTE_MANIFEST"
export MEMO_MANIFEST_PATH="$MEMO_MANIFEST"

mkdir -p "$(dirname "$OUTPUT_DIR")" "$(dirname "$ARCHIVE_PATH")"
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/review-notes" "$OUTPUT_DIR/review-memos"

bash "$RUNNER" --handoff-index > "$OUTPUT_DIR/handoff-index.txt"
bash "$RUNNER" --landing-plan > "$OUTPUT_DIR/landing-plan.txt"
bash "$RUNNER" --landing-plan --show > "$OUTPUT_DIR/landing-plan-expanded.txt"
bash "$LANDING_RENDERER" "$OUTPUT_DIR/landing-plan-expanded.txt" > "$OUTPUT_DIR/landing-summary.md"
bash "$LANDING_DRAFT_RENDERER" "$OUTPUT_DIR/landing-plan-expanded.txt" > "$OUTPUT_DIR/landing-drafts.md"
bash "$RUNNER" --status-all > "$OUTPUT_DIR/status-all.txt"
bash "$RUNNER" --next > "$OUTPUT_DIR/next.txt"
bash "$RUNNER" --next --verbose > "$OUTPUT_DIR/next-verbose.txt"
bash "$RUNNER" --note-manifest > "$OUTPUT_DIR/note-manifest-report.txt"
bash "$RUNNER" --memo-manifest > "$OUTPUT_DIR/memo-manifest-report.txt"

if [ -f "$NOTE_MANIFEST" ]; then
  cp "$NOTE_MANIFEST" "$OUTPUT_DIR/review-batch-note-manifest.txt"
fi

if [ -f "$MEMO_MANIFEST" ]; then
  cp "$MEMO_MANIFEST" "$OUTPUT_DIR/review-batch-memo-manifest.txt"
fi

if [ -d "$REVIEW_NOTES_DIR" ]; then
  find "$REVIEW_NOTES_DIR" -maxdepth 1 -type f -name '*.txt' -print0 \
    | while IFS= read -r -d '' file; do
        cp "$file" "$OUTPUT_DIR/review-notes/"
      done
fi

if [ -d "$REVIEW_MEMOS_DIR" ]; then
  find "$REVIEW_MEMOS_DIR" -maxdepth 1 -type f -name '*.txt' -print0 \
    | while IFS= read -r -d '' file; do
        cp "$file" "$OUTPUT_DIR/review-memos/"
      done
fi

tar -czf "$ARCHIVE_PATH" -C "$(dirname "$OUTPUT_DIR")" "$(basename "$OUTPUT_DIR")"

printf '%s\n' "REVIEW-HANDOFF-PACK | output-dir=$OUTPUT_DIR | archive=$ARCHIVE_PATH"
