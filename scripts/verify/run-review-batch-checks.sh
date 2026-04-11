#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BATCH_TIMEOUT_SECONDS="${BATCH_TIMEOUT_SECONDS:-0}"
RUN_FULL_BROWSER_UI_SMOKE="${RUN_FULL_BROWSER_UI_SMOKE:-0}"
NOTE_MANIFEST_PATH="${NOTE_MANIFEST_PATH:-$ROOT_DIR/.artifacts/review-batch-note-manifest.txt}"
MEMO_MANIFEST_PATH="${MEMO_MANIFEST_PATH:-$ROOT_DIR/.artifacts/review-batch-memo-manifest.txt}"
OUTSIDE_LANDING_DRAFT_MANIFEST_PATH="${OUTSIDE_LANDING_DRAFT_MANIFEST_PATH:-$ROOT_DIR/.artifacts/review-draft-manifest.txt}"

outside_landing_commit_title() {
  local batch_name="$1"
  printf '%s\n' "chore(review): land ${batch_name} batch"
}

outside_landing_pr_title() {
  local batch_name="$1"
  printf '%s\n' "Land ${batch_name} handoff bundle"
}

usage() {
  cat <<'EOF'
Usage:
  ./scripts/verify/run-review-batch-checks.sh
  ./scripts/verify/run-review-batch-checks.sh batch-1 batch-3
  ./scripts/verify/run-review-batch-checks.sh --list
  ./scripts/verify/run-review-batch-checks.sh --describe
  ./scripts/verify/run-review-batch-checks.sh --files batch-4
  ./scripts/verify/run-review-batch-checks.sh --split batch-2
  ./scripts/verify/run-review-batch-checks.sh --split batch-2 --filter tracked-modified
  ./scripts/verify/run-review-batch-checks.sh --untracked-groups batch-2
  ./scripts/verify/run-review-batch-checks.sh --untracked-groups batch-2 --name regression-suites
  ./scripts/verify/run-review-batch-checks.sh --diff batch-2
  ./scripts/verify/run-review-batch-checks.sh --diff batch-2 --filter tracked-modified
  ./scripts/verify/run-review-batch-checks.sh --hunks batch-2 --filter tracked-modified
  ./scripts/verify/run-review-batch-checks.sh --subchanges batch-2 --filter tracked-modified
  ./scripts/verify/run-review-batch-checks.sh --subchanges batch-2 --filter tracked-modified --name bounded-wait-guards
  ./scripts/verify/run-review-batch-checks.sh --subchanges batch-2 --filter tracked-modified --name bounded-wait-guards --detail
  ./scripts/verify/run-review-batch-checks.sh --note batch-2 --filter tracked-modified --name bounded-wait-guards
  ./scripts/verify/run-review-batch-checks.sh --note batch-2 --filter tracked-modified --name bounded-wait-guards --write .artifacts/bounded-wait-guards-note.txt
  ./scripts/verify/run-review-batch-checks.sh --note-manifest
  ./scripts/verify/run-review-batch-checks.sh --note-manifest --latest
  ./scripts/verify/run-review-batch-checks.sh --note-manifest --latest --show
  ./scripts/verify/run-review-batch-checks.sh --memo batch-2 --filter tracked-modified
  ./scripts/verify/run-review-batch-checks.sh --memo batch-2 --filter tracked-modified --write .artifacts/batch-2-tracked-memo.txt
  ./scripts/verify/run-review-batch-checks.sh --memo-manifest
  ./scripts/verify/run-review-batch-checks.sh --memo-manifest --latest
  ./scripts/verify/run-review-batch-checks.sh --memo-manifest --latest --show
  ./scripts/verify/run-review-batch-checks.sh --handoff-index
  ./scripts/verify/run-review-batch-checks.sh --handoff-index batch-2 --show
  ./scripts/verify/run-review-batch-checks.sh --landing-plan
  ./scripts/verify/run-review-batch-checks.sh --landing-plan batch-2 --show
  ./scripts/verify/run-review-batch-checks.sh --landing-commands
  ./scripts/verify/run-review-batch-checks.sh --landing-commands batch-2 outside-frontend-runtime
  ./scripts/verify/run-review-batch-checks.sh --status batch-4
  ./scripts/verify/run-review-batch-checks.sh --status-all
  ./scripts/verify/run-review-batch-checks.sh --outside-batches
  ./scripts/verify/run-review-batch-checks.sh --outside-batch-groups
  ./scripts/verify/run-review-batch-checks.sh --outside-batch-groups --name facilitator-runtime
  ./scripts/verify/run-review-batch-checks.sh --outside-batch-plan
  ./scripts/verify/run-review-batch-checks.sh --outside-batch-plan --show
  ./scripts/verify/run-review-batch-checks.sh --outside-landing-batches
  ./scripts/verify/run-review-batch-checks.sh --outside-landing-batches --name outside-frontend-runtime --show
  ./scripts/verify/run-review-batch-checks.sh --outside-landing-batches --show
  ./scripts/verify/run-review-batch-checks.sh --outside-landing-draft --name outside-frontend-runtime
  ./scripts/verify/run-review-batch-checks.sh --outside-landing-draft --name outside-frontend-runtime --write .artifacts/review-drafts/outside-frontend-runtime.md
  ./scripts/verify/run-review-batch-checks.sh --outside-batch-note --name frontend-runtime
  ./scripts/verify/run-review-batch-checks.sh --outside-batch-note --name frontend-runtime --write .artifacts/review-notes/outside-batches-frontend-runtime.txt
  ./scripts/verify/run-review-batch-checks.sh --outside-batch-memo
  ./scripts/verify/run-review-batch-checks.sh --outside-batch-memo --write .artifacts/review-memos/outside-batches-outside-batch-memo.txt
  ./scripts/verify/run-review-batch-checks.sh --next
  ./scripts/verify/run-review-batch-checks.sh --next --verbose

Supported review batches:
  batch-1  Backend lifecycle and validation tests
  batch-2  CKA 2026 regressions and diagnostics tooling
  batch-3  Browser smoke and verify package wiring
  batch-4  Workflow wiring
  batch-5  Audit and rollout notes

Notes:
  - The runner executes the selected batch checks sequentially.
  - Use --files to print the landing manifest for one or more review batches.
  - Use --split to print per-state landing subsets for one or more review batches.
  - Use --split --filter <state> to narrow the subset view to clean, tracked-modified, untracked, or missing.
  - Use --untracked-groups to print curated landing groupings for untracked files when a batch has many new files.
  - Use --untracked-groups --name <group> to narrow the view to one untracked landing group such as regression-suites.
  - Use --diff to print git diff summaries for the tracked-modified subset of one or more review batches.
  - Use --diff --filter tracked-modified to make that target explicit for mixed landing batches.
  - Use --hunks to print tracked-modified hunk boundaries and scopes so one file can be split into landing-sized sub-changes.
  - Use --subchanges to print named landing-sized review groups for tracked-modified files when a curated split map exists.
  - Use --subchanges --name <subchange> to narrow the review to one named landing group such as bounded-wait-guards.
  - Use --subchanges --name <subchange> --detail to print only the hunk scopes that fall inside that named landing group.
  - Use --note --name <subchange> to print a structured landing note for one named subchange.
  - Use --note --name <subchange> --write <path> to save that landing note as a file for handoff or review notes.
  - Use --note-manifest to inspect generated note artifacts recorded under NOTE_MANIFEST_PATH.
  - Use --note-manifest --latest to inspect only the most recent recorded note artifact.
  - Use --note-manifest --show to print the selected note artifact contents with NOTE-CONTENT prefixes.
  - Set NOTE_MANIFEST_PATH to override where note write records are appended.
  - Use --memo to print a structured landing memo for every named tracked-modified subchange in a batch.
  - Use --memo --write <path> to save that landing memo as a file for handoff or review notes.
  - Use --memo-manifest to inspect generated memo artifacts recorded under MEMO_MANIFEST_PATH.
  - Use --memo-manifest --latest to inspect only the most recent recorded memo artifact.
  - Use --memo-manifest --show to print the selected memo artifact contents with MEMO-CONTENT prefixes.
  - Use --handoff-index to print a batch-by-batch summary of generated note/memo artifacts.
  - Use --handoff-index --show to expand one or more batches into NOTE-ARTIFACT and MEMO-ARTIFACT lines.
  - Use --landing-plan to print the commit-order landing plan once handoff artifacts exist.
  - Use --landing-plan --show to expand one or more batches into landing files and latest artifact references.
  - Use --landing-commands to print copy-pasteable git add / git commit drafts for ready-for-landing batches and outside landing groups.
  - Use --landing-commands <target> to narrow that output to one primary batch such as batch-2 or one formal outside landing batch such as outside-frontend-runtime.
  - Set MEMO_MANIFEST_PATH to override where memo write records are appended.
  - Use --status to print file counts, git state drift, and readiness for one or more review batches.
  - Use --status-all to print readiness-sorted summaries for every batch plus aggregate verdict lines.
  - Use --outside-batches to print tracked-modified and untracked changes that are not covered by any current batch manifest.
  - Use --outside-batch-groups to print curated landing groups for files currently outside the review-batch manifests.
  - Use --outside-batch-groups --name <group> to narrow that view to one group such as facilitator-runtime.
  - Use --outside-batch-plan to print those outside-batch groups as ordered next landing candidates.
  - Use --outside-batch-plan --show to expand the plan into per-file rows.
  - Use --outside-landing-batches to print those outside-batch groups as formal LANDING-STEP rows once note/memo handoff is complete.
  - Use --outside-landing-batches --name <outside-group> --show to narrow that formal landing view to one outside landing batch such as outside-frontend-runtime.
  - Use --outside-landing-batches --show to expand those landing steps into LANDING-HANDOFF, LANDING-FILE, and LANDING-ARTIFACT rows.
  - Use --outside-landing-draft --name <outside-group> to print a commit/PR draft for one formal outside landing batch.
  - Use --outside-landing-draft --name <outside-group> --write <path> to materialize that draft under .artifacts/review-drafts/.
  - Use --outside-batch-note --name <group> to turn one curated outside-batch group into a reusable handoff note.
  - Use --outside-batch-note --name <group> --write <path> to materialize that outside-batch handoff note on disk.
  - Use --outside-batch-memo to collapse all matched outside-batch groups into one grouped memo.
  - Use --outside-batch-memo --write <path> to materialize that outside-batch memo on disk.
  - Use --next to print only the next recommended review command.
  - Use --next --verbose to print the next command plus the batch or outside-batch cause, counts, and focus file behind that recommendation.
  - Set BATCH_TIMEOUT_SECONDS=0 to disable the per-batch timeout wrapper.
  - Set RUN_FULL_BROWSER_UI_SMOKE=1 to include the Playwright-backed browser smoke in batch-3.
EOF
}

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

resolve_batch_order() {
  case "$1" in
    batch-1) printf '%s\n' '1' ;;
    batch-2) printf '%s\n' '2' ;;
    batch-3) printf '%s\n' '3' ;;
    batch-4) printf '%s\n' '4' ;;
    batch-5) printf '%s\n' '5' ;;
    *)
      echo "Unknown review batch: $1" >&2
      exit 1
      ;;
  esac
}

resolve_batch_commit_scope() {
  case "$1" in
    batch-1) printf '%s\n' 'backend-tests' ;;
    batch-2) printf '%s\n' 'cka-regressions-and-diagnostics' ;;
    batch-3) printf '%s\n' 'browser-verify' ;;
    batch-4) printf '%s\n' 'workflow-wiring' ;;
    batch-5) printf '%s\n' 'review-docs' ;;
    *)
      echo "Unknown review batch: $1" >&2
      exit 1
      ;;
  esac
}

resolve_batch_commit_title() {
  local batch="$1"
  local scope=""

  scope="$(resolve_batch_commit_scope "$batch")"
  printf '%s\n' "chore(review): land ${scope} batch"
}

resolve_batch_pr_title() {
  local batch="$1"
  local scope=""

  scope="$(resolve_batch_commit_scope "$batch")"
  printf '%s\n' "Land ${batch} (${scope}) handoff bundle"
}

build_git_add_command() {
  local files=("$@")
  local file=""

  if [ "${#files[@]}" -eq 0 ]; then
    printf '%s\n' "echo no-files-to-stage"
    return 0
  fi

  printf '%s' "git add --"
  for file in "${files[@]}"; do
    printf ' %q' "$file"
  done
  printf '\n'
}

build_git_commit_command() {
  local title="$1"
  printf 'git commit -m %q\n' "$title"
}

describe_batch() {
  case "$1" in
    batch-1)
      printf '%s\n' 'batch-1 | facilitator unit tests | app/service/redis/validator lifecycle coverage'
      ;;
    batch-2)
      printf '%s\n' 'batch-2 | regression/diagnostics checks | CKA runner list plus diagnostics, landing-summary/draft, and review handoff contract smokes'
      ;;
    batch-3)
      printf '%s\n' 'batch-3 | browser verify wiring | browser scenario contract plus browser-ui-smoke:list, optional full Playwright smoke'
      ;;
    batch-4)
      printf '%s\n' 'batch-4 | workflow wiring | workflow contract smoke plus YAML parse for CI and self-hosted workflows'
      ;;
    batch-5)
      printf '%s\n' 'batch-5 | audit and rollout notes | review inventory / verify README presence and batch validation map alignment'
      ;;
    *)
      echo "Unknown review batch: $1" >&2
      exit 1
      ;;
  esac
}

resolve_batch_files() {
  case "$1" in
    batch-1)
      cat <<'EOF'
facilitator/tests/app.test.js
facilitator/tests/examService.test.js
facilitator/tests/redisClient.test.js
facilitator/tests/validators.test.js
EOF
      ;;
    batch-2)
      cat <<'EOF'
scripts/verify/cka-003-dedicated-dns-e2e.sh
scripts/verify/cka-004-cluster-dns-e2e.sh
scripts/verify/cka-005-isolated-env-e2e.sh
scripts/verify/run-cka-2026-regressions.sh
scripts/verify/collect-cka-2026-diagnostics.sh
scripts/verify/pack-cka-2026-diagnostics.sh
scripts/verify/pack-review-batch-handoff.sh
scripts/verify/render-cka-2026-summary-markdown.sh
scripts/verify/render-review-landing-drafts.sh
scripts/verify/render-review-landing-summary.sh
scripts/verify/run-verify-contract-smokes.sh
scripts/verify/run-review-batch-checks.sh
scripts/verify/cka-2026-diagnostics-collector-smoke.sh
scripts/verify/cka-2026-diagnostics-pack-smoke.sh
scripts/verify/cka-2026-summary-renderer-smoke.sh
scripts/verify/review-batch-handoff-pack-smoke.sh
EOF
      ;;
    batch-3)
      cat <<'EOF'
scripts/verify/browser-ui-smoke.mjs
scripts/verify/browser-ui-scenario-contract-smoke.sh
scripts/verify/package.json
scripts/verify/README.md
EOF
      ;;
    batch-4)
      cat <<'EOF'
.github/workflows/ci.yml
.github/workflows/cka-2026-regressions.yml
.github/workflows/review-batch-checks.yml
scripts/verify/cka-2026-workflow-contract-smoke.sh
scripts/verify/review-batch-workflow-contract-smoke.sh
EOF
      ;;
    batch-5)
      cat <<'EOF'
docs/reports/codebase-audit-2026-04-10.md
docs/reports/review-inventory-2026-04-10.md
EOF
      ;;
    *)
      echo "Unknown review batch: $1" >&2
      exit 1
      ;;
  esac
}

print_batch_files() {
  local batch="$1"
  while IFS= read -r file; do
    [ -n "$file" ] || continue
    printf '%s | %s\n' "$batch" "$file"
  done < <(resolve_batch_files "$batch")
}

validate_split_filter() {
  case "$1" in
    clean|tracked-modified|untracked|missing)
      ;;
    *)
      echo "Unknown split filter: $1" >&2
      echo "Supported split filters: clean, tracked-modified, untracked, missing" >&2
      exit 1
      ;;
  esac
}

validate_diff_filter() {
  case "$1" in
    tracked-modified)
      ;;
    *)
      echo "Unknown diff filter: $1" >&2
      echo "Supported diff filters: tracked-modified" >&2
      exit 1
      ;;
  esac
}

validate_hunk_filter() {
  case "$1" in
    tracked-modified)
      ;;
    *)
      echo "Unknown hunk filter: $1" >&2
      echo "Supported hunk filters: tracked-modified" >&2
      exit 1
      ;;
  esac
}

validate_subchange_filter() {
  case "$1" in
    tracked-modified)
      ;;
    *)
      echo "Unknown subchange filter: $1" >&2
      echo "Supported subchange filters: tracked-modified" >&2
      exit 1
      ;;
  esac
}

validate_note_filter() {
  case "$1" in
    tracked-modified|untracked)
      ;;
    *)
      echo "Unknown note filter: $1" >&2
      echo "Supported note filters: tracked-modified, untracked" >&2
      exit 1
      ;;
  esac
}

validate_memo_filter() {
  case "$1" in
    tracked-modified|untracked)
      ;;
    *)
      echo "Unknown memo filter: $1" >&2
      echo "Supported memo filters: tracked-modified, untracked" >&2
      exit 1
      ;;
  esac
}

print_batch_split() {
  local batch="$1"
  local filter="${2:-}"

  compute_batch_status "$batch"
  if [ -n "$filter" ]; then
    validate_split_filter "$filter"
    case "$filter" in
      clean)
        printf '%s | subset=clean | count=%s\n' "$batch" "$BATCH_STATUS_CLEAN"
        ;;
      tracked-modified)
        printf '%s | subset=tracked-modified | count=%s\n' "$batch" "$BATCH_STATUS_TRACKED_MODIFIED"
        for file in "${BATCH_STATUS_TRACKED_MODIFIED_FILES[@]}"; do
          printf '%s | FILE | tracked-modified | %s\n' "$batch" "$file"
        done
        ;;
      untracked)
        printf '%s | subset=untracked | count=%s\n' "$batch" "$BATCH_STATUS_UNTRACKED"
        for file in "${BATCH_STATUS_UNTRACKED_FILES[@]}"; do
          printf '%s | FILE | untracked | %s\n' "$batch" "$file"
        done
        ;;
      missing)
        printf '%s | subset=missing | count=%s\n' "$batch" "$BATCH_STATUS_MISSING"
        for file in "${BATCH_STATUS_MISSING_FILES[@]}"; do
          printf '%s | FILE | missing | %s\n' "$batch" "$file"
        done
        ;;
    esac
    return 0
  fi

  printf '%s | subset=clean | count=%s\n' "$batch" "$BATCH_STATUS_CLEAN"
  printf '%s | subset=tracked-modified | count=%s\n' "$batch" "$BATCH_STATUS_TRACKED_MODIFIED"
  printf '%s | subset=untracked | count=%s\n' "$batch" "$BATCH_STATUS_UNTRACKED"
  printf '%s | subset=missing | count=%s\n' "$batch" "$BATCH_STATUS_MISSING"

  for file in "${BATCH_STATUS_TRACKED_MODIFIED_FILES[@]}"; do
    printf '%s | FILE | tracked-modified | %s\n' "$batch" "$file"
  done
  for file in "${BATCH_STATUS_UNTRACKED_FILES[@]}"; do
    printf '%s | FILE | untracked | %s\n' "$batch" "$file"
  done
  for file in "${BATCH_STATUS_MISSING_FILES[@]}"; do
    printf '%s | FILE | missing | %s\n' "$batch" "$file"
  done
}

print_batch_untracked_groups() {
  local batch="$1"
  local selected_name="${2:-}"
  local definition name focus files_csv
  local file_count=0 group_count=0
  local file
  local -a matched_files=()

  compute_batch_status "$batch"

  while IFS='|' read -r name focus files_csv; do
    [ -n "$name" ] || continue
    if [ -n "$selected_name" ] && [ "$name" != "$selected_name" ]; then
      continue
    fi

    matched_files=()
    IFS=';' read -r -a group_files <<< "$files_csv"
    for file in "${group_files[@]}"; do
      [ -n "$file" ] || continue
      if printf '%s\n' "${BATCH_STATUS_UNTRACKED_FILES[@]}" | grep -Fxq "$file"; then
        matched_files+=("$file")
      fi
    done

    if [ "${#matched_files[@]}" -eq 0 ]; then
      continue
    fi

    group_count=$((group_count + 1))
    file_count=$((file_count + ${#matched_files[@]}))
    printf '%s | UNTRACKED-GROUP | name=%s | file-count=%s | focus=%s\n' \
      "$batch" \
      "$name" \
      "${#matched_files[@]}" \
      "$focus"
    for file in "${matched_files[@]}"; do
      printf '%s | UNTRACKED-FILE | group=%s | %s\n' \
        "$batch" \
        "$name" \
        "$file"
    done
  done < <(emit_untracked_group_definitions_for_batch "$batch")

  printf '%s | untracked-group-subset=untracked | name=%s | group-count=%s | file-count=%s\n' \
    "$batch" \
    "${selected_name:-all}" \
    "$group_count" \
    "$file_count"
}

resolve_outside_batch_groups() {
  cat <<'EOF'
frontend-runtime|app/public/js/index.js|app/public/js/components/terminal-service.js;app/public/js/exam.js;app/public/js/index.js;app/public/js/results.js;docs/webapp/index-functionality.md
facilitator-runtime|facilitator/src/services/examService.js|facilitator/package.json;facilitator/src/app.js;facilitator/src/controllers/examController.js;facilitator/src/middleware/validators.js;facilitator/src/routes/assessmentRoutes.js;facilitator/src/services/examService.js;facilitator/src/utils/redisClient.js;facilitator/tests/jumphostService.test.js
exam-content|facilitator/assets/exams/cka/003/assessment.json|docs/templates/cka-2026-top3/README.md;facilitator/assets/exams/cka/003/answers.md;facilitator/assets/exams/cka/003/assessment.json;facilitator/assets/exams/cka/003/scripts/validation/q1_s2_validate_pod_running.sh;facilitator/assets/exams/cka/003/scripts/validation/q2_s1_validate_coredns_ready.sh;facilitator/assets/exams/cka/003/scripts/validation/q2_s2_validate_dns_resolution.sh;facilitator/assets/exams/cka/003/scripts/validation/q3_s1_validate_controller.sh;facilitator/assets/exams/cka/003/scripts/validation/q3_s3_validate_ingress_route.sh;facilitator/assets/exams/cka/004/scripts/validation/q1_s1_validate_coredns_config.sh;facilitator/assets/exams/cka/004/scripts/validation/q1_s2_validate_dns_resolution.sh;facilitator/assets/exams/cka/005/scripts/validation/q1_s2_validate_pod_running.sh;facilitator/assets/exams/cka/005/scripts/validation/q2_s1_validate_controller.sh;facilitator/assets/exams/cka/005/scripts/validation/q2_s3_validate_ingress_route.sh;facilitator/assets/exams/cka/005/scripts/validation/q3_s1_validate_coredns_config.sh;facilitator/assets/exams/cka/005/scripts/validation/q3_s2_validate_dns_resolution.sh;facilitator/assets/exams/labs.json
infra-runtime|jumphost/scripts/prepare-exam-env.sh|compose-deploy.sh;jumphost/scripts/cleanup-exam-env.sh;jumphost/scripts/prepare-exam-env.sh;kind-cluster/scripts/env-kubeconfig;kind-cluster/scripts/env-setup;nginx/default.conf;remote-desktop/Dockerfile;remote-desktop/Dockerfile.qemu;scripts/lib/container-runtime.sh;scripts/verify/ckad-003-podman-smoke.sh
rollout-docs|README.md|.gitignore;README.md;docs/development-setup.md;docs/local-setup-guide.md;facilitator/README.md;scripts/COMPOSE-DEPLOY.md;scripts/install.ps1;scripts/install.sh
EOF
}

print_outside_batch_groups() {
  local selected_name="${1:-}"
  local definition name focus files_csv file state
  local group_total=0 matched_groups=0 matched_files=0 unmatched_files=0
  local -a group_files=()
  local -a matched_paths=()

  collect_outside_batch_changes
  while IFS='|' read -r name focus files_csv; do
    [ -n "$name" ] || continue
    group_total=$((group_total + 1))
    if [ -n "$selected_name" ] && [ "$name" != "$selected_name" ]; then
      continue
    fi

    matched_paths=()
    IFS=';' read -r -a group_files <<< "$files_csv"
    for file in "${group_files[@]}"; do
      [ -n "$file" ] || continue
      if printf '%s\n' "${OUTSIDE_BATCH_TRACKED_MODIFIED_FILES[@]}" | grep -Fxq "$file" || \
         printf '%s\n' "${OUTSIDE_BATCH_UNTRACKED_FILES[@]}" | grep -Fxq "$file"; then
        matched_paths+=("$file")
      fi
    done

    if [ "${#matched_paths[@]}" -eq 0 ]; then
      continue
    fi

    matched_groups=$((matched_groups + 1))
    matched_files=$((matched_files + ${#matched_paths[@]}))
    printf '%s | name=%s | focus=%s | file-count=%s\n' \
      "OUTSIDE-BATCH-GROUP" \
      "$name" \
      "$focus" \
      "${#matched_paths[@]}"
    for file in "${matched_paths[@]}"; do
      state="tracked-modified"
      if printf '%s\n' "${OUTSIDE_BATCH_UNTRACKED_FILES[@]}" | grep -Fxq "$file"; then
        state="untracked"
      fi
      printf '%s | %s | %s | %s\n' \
        "OUTSIDE-BATCH-GROUP-FILE" \
        "$name" \
        "$state" \
        "$file"
    done
  done < <(resolve_outside_batch_groups)

  unmatched_files=$((OUTSIDE_BATCH_TOTAL - matched_files))
  printf '%s | total=%s | matched-groups=%s | unmatched-files=%s\n' \
    "OUTSIDE-BATCH-GROUPS" \
    "$OUTSIDE_BATCH_TOTAL" \
    "$matched_groups" \
    "$unmatched_files"
}

print_outside_batch_plan() {
  local show="${1:-0}"
  local definition name focus files_csv file state
  local matched_groups=0 matched_files=0 unmatched_files=0 tracked_modified=0 untracked=0 order=0
  local -a group_files=()
  local -a matched_paths=()

  collect_outside_batch_changes

  while IFS='|' read -r name focus files_csv; do
    [ -n "$name" ] || continue

    matched_paths=()
    tracked_modified=0
    untracked=0
    IFS=';' read -r -a group_files <<< "$files_csv"
    for file in "${group_files[@]}"; do
      [ -n "$file" ] || continue
      if printf '%s\n' "${OUTSIDE_BATCH_TRACKED_MODIFIED_FILES[@]}" | grep -Fxq "$file"; then
        matched_paths+=("$file")
        tracked_modified=$((tracked_modified + 1))
      elif printf '%s\n' "${OUTSIDE_BATCH_UNTRACKED_FILES[@]}" | grep -Fxq "$file"; then
        matched_paths+=("$file")
        untracked=$((untracked + 1))
      fi
    done

    if [ "${#matched_paths[@]}" -eq 0 ]; then
      continue
    fi

    order=$((order + 1))
    matched_groups=$((matched_groups + 1))
    matched_files=$((matched_files + ${#matched_paths[@]}))
    printf '%s | order=%s | name=%s | focus=%s | file-count=%s | tracked-modified=%s | untracked=%s\n' \
      "OUTSIDE-LANDING-STEP" \
      "$order" \
      "$name" \
      "$focus" \
      "${#matched_paths[@]}" \
      "$tracked_modified" \
      "$untracked"
    if [ "$show" = "1" ]; then
      for file in "${matched_paths[@]}"; do
        state="tracked-modified"
        if printf '%s\n' "${OUTSIDE_BATCH_UNTRACKED_FILES[@]}" | grep -Fxq "$file"; then
          state="untracked"
        fi
        printf '%s | %s | %s | %s\n' \
          "OUTSIDE-LANDING-FILE" \
          "$name" \
          "$state" \
          "$file"
      done
    fi
  done < <(resolve_outside_batch_groups)

  unmatched_files=$((OUTSIDE_BATCH_TOTAL - matched_files))
  printf '%s | groups=%s | total=%s | matched-files=%s | unmatched-files=%s\n' \
    "OUTSIDE-LANDING-SUMMARY" \
    "$matched_groups" \
    "$OUTSIDE_BATCH_TOTAL" \
    "$matched_files" \
    "$unmatched_files"
}

resolve_outside_landing_batch_name() {
  local name="$1"
  printf '%s\n' "outside-${name}"
}

normalize_outside_landing_batch_selection() {
  local name="${1:-}"

  case "$name" in
    outside-*)
      printf '%s\n' "${name#outside-}"
      ;;
    *)
      printf '%s\n' "$name"
      ;;
  esac
}

resolve_outside_landing_batch_next_command() {
  local name="$1"
  local batch_name=""

  if ! note_manifest_has_recorded_output "outside-batches" "outside-batch" "$name"; then
    printf '%s\n' "./scripts/verify/run-review-batch-checks.sh --outside-batch-note --name ${name} --write $(default_outside_batch_note_write_path "$name")"
    return 0
  fi

  if ! memo_manifest_has_recorded_output "outside-batches" "outside-batch"; then
    printf '%s\n' "./scripts/verify/run-review-batch-checks.sh --outside-batch-memo --write $(default_outside_batch_memo_write_path)"
    return 0
  fi

  batch_name="$(resolve_outside_landing_batch_name "$name")"
  if outside_landing_draft_manifest_has_recorded_output "$name"; then
    printf '%s\n' "echo no-pending-review-actions"
    return 0
  fi
  printf '%s\n' "./scripts/verify/run-review-batch-checks.sh --outside-landing-draft --name ${batch_name} --write $(default_outside_landing_draft_write_path "$batch_name")"
}

resolve_outside_landing_batch_artifact_state() {
  local name="$1"
  local note_present="0"
  local memo_present="0"

  if note_manifest_has_recorded_output "outside-batches" "outside-batch" "$name"; then
    note_present="1"
  fi
  if memo_manifest_has_recorded_output "outside-batches" "outside-batch"; then
    memo_present="1"
  fi

  if [ "$note_present" = "1" ] && [ "$memo_present" = "1" ]; then
    printf '%s\n' "complete"
    return 0
  fi
  if [ "$note_present" = "0" ] && [ "$memo_present" = "0" ]; then
    printf '%s\n' "none"
    return 0
  fi
  printf '%s\n' "partial"
}

resolve_outside_landing_batch_state() {
  local artifact_state="$1"

  case "$artifact_state" in
    complete) printf '%s\n' "ready-for-landing" ;;
    *) printf '%s\n' "pending-handoff" ;;
  esac
}

print_outside_landing_batches() {
  local show="${1:-0}"
  local selected_name_raw="${2:-}"
  local selected_name=""
  local name focus files_csv file state
  local -a matched_paths=()
  local -a group_files=()
  local order=0 matched_groups=0
  local total_selected_groups=0
  local tracked_modified=0 untracked=0
  local ready_for_landing=0 pending_handoff=0 blocked=0
  local batch_name artifact_state landing_state next_command

  collect_outside_batch_changes
  selected_name="$(normalize_outside_landing_batch_selection "$selected_name_raw")"
  total_selected_groups="$(count_selected_outside_landing_batches "$selected_name")"
  printf '%s | batches=%s\n' "LANDING-PLAN" "$total_selected_groups"

  while IFS='|' read -r name focus files_csv; do
    [ -n "$name" ] || continue
    if [ -n "$selected_name" ] && [ "$name" != "$selected_name" ]; then
      continue
    fi

    matched_paths=()
    tracked_modified=0
    untracked=0
    IFS=';' read -r -a group_files <<< "$files_csv"
    for file in "${group_files[@]}"; do
      [ -n "$file" ] || continue
      if printf '%s\n' "${OUTSIDE_BATCH_TRACKED_MODIFIED_FILES[@]}" | grep -Fxq "$file"; then
        matched_paths+=("$file")
        tracked_modified=$((tracked_modified + 1))
      elif printf '%s\n' "${OUTSIDE_BATCH_UNTRACKED_FILES[@]}" | grep -Fxq "$file"; then
        matched_paths+=("$file")
        untracked=$((untracked + 1))
      fi
    done

    if [ "${#matched_paths[@]}" -eq 0 ]; then
      continue
    fi

    order=$((order + 1))
    matched_groups=$((matched_groups + 1))
    batch_name="$(resolve_outside_landing_batch_name "$name")"
    artifact_state="$(resolve_outside_landing_batch_artifact_state "$name")"
    landing_state="$(resolve_outside_landing_batch_state "$artifact_state")"
    next_command="$(resolve_outside_landing_batch_next_command "$name")"

    printf '%s | LANDING-STEP | order=%s | landing-state=%s | readiness=needs-landing | handoff=%s | artifact-state=%s | commit-scope=%s | focus=%s | files=%s | tracked-modified=%s | untracked=%s | missing=0\n' \
      "$batch_name" \
      "$order" \
      "$landing_state" \
      "$artifact_state" \
      "$artifact_state" \
      "$batch_name" \
      "$focus" \
      "${#matched_paths[@]}" \
      "$tracked_modified" \
      "$untracked"

    case "$landing_state" in
      ready-for-landing) ready_for_landing=$((ready_for_landing + 1)) ;;
      pending-handoff) pending_handoff=$((pending_handoff + 1)) ;;
      blocked) blocked=$((blocked + 1)) ;;
    esac

    if [ "$show" = "1" ]; then
      printf '%s | LANDING-HANDOFF | next=%s\n' "$batch_name" "$next_command"
      for file in "${matched_paths[@]}"; do
        state="tracked-modified"
        if printf '%s\n' "${OUTSIDE_BATCH_UNTRACKED_FILES[@]}" | grep -Fxq "$file"; then
          state="untracked"
        fi
        printf '%s | LANDING-FILE | %s | %s\n' "$batch_name" "$state" "$file"
      done
      printf '%s | LANDING-ARTIFACT | type=latest-note | path=%s\n' "$batch_name" "$(default_outside_batch_note_write_path "$name")"
      printf '%s | LANDING-ARTIFACT | type=latest-memo | path=%s\n' "$batch_name" "$(default_outside_batch_memo_write_path)"
    fi
  done < <(resolve_outside_batch_groups)

  printf '%s | ready-for-landing=%s | pending-handoff=%s | blocked=%s\n' \
    "LANDING-PLAN-SUMMARY" \
    "$ready_for_landing" \
    "$pending_handoff" \
    "$blocked"
}

print_outside_landing_draft() {
  local selected_name_raw="$1"
  local selected_name=""
  local name focus files_csv file state
  local artifact_note=""
  local artifact_memo=""
  local -a group_files=()
  local -a tracked_files=()
  local -a untracked_files=()
  local batch_name=""

  if [ -z "$selected_name_raw" ]; then
    echo "--outside-landing-draft requires --name <outside-group>" >&2
    return 1
  fi

  collect_outside_batch_changes
  selected_name="$(normalize_outside_landing_batch_selection "$selected_name_raw")"

  while IFS='|' read -r name focus files_csv; do
    [ -n "$name" ] || continue
    if [ "$name" != "$selected_name" ]; then
      continue
    fi

    batch_name="$(resolve_outside_landing_batch_name "$name")"
    IFS=';' read -r -a group_files <<< "$files_csv"
    for file in "${group_files[@]}"; do
      [ -n "$file" ] || continue
      if printf '%s\n' "${OUTSIDE_BATCH_TRACKED_MODIFIED_FILES[@]}" | grep -Fxq "$file"; then
        tracked_files+=("$file")
      elif printf '%s\n' "${OUTSIDE_BATCH_UNTRACKED_FILES[@]}" | grep -Fxq "$file"; then
        untracked_files+=("$file")
      fi
    done
    if [ "${#tracked_files[@]}" -eq 0 ] && [ "${#untracked_files[@]}" -eq 0 ]; then
      echo "No outside landing batch named '${selected_name_raw}' currently matches repo drift" >&2
      return 1
    fi

    artifact_note="$(default_outside_batch_note_write_path "$name")"
    artifact_memo="$(default_outside_batch_memo_write_path)"

    printf '## %s\n\n' "$batch_name"
    printf -- '- Commit title: `%s`\n' "$(outside_landing_commit_title "$batch_name")"
    printf -- '- PR title: `%s`\n' "$(outside_landing_pr_title "$batch_name")"
    printf -- '- Landing state: `%s`\n' "ready-for-landing"
    printf -- '- Readiness: `%s`\n' "needs-landing"
    printf -- '- Handoff: `%s`\n' "complete"
    printf -- '- Artifact state: `%s`\n' "complete"
    printf -- '- Focus: `%s`\n' "$focus"
    printf -- '- File counts: `%d total / %d tracked-modified / %d untracked`\n' "$(( ${#tracked_files[@]} + ${#untracked_files[@]} ))" "${#tracked_files[@]}" "${#untracked_files[@]}"
    printf -- '- Next command: `%s`\n' "echo no-pending-review-actions"
    printf -- '- Latest note: `%s`\n' "$artifact_note"
    printf -- '- Grouped memo: `%s`\n' "$artifact_memo"
    printf '\nFiles:\n'
    for file in "${tracked_files[@]}"; do
      printf -- '- `tracked-modified`: `%s`\n' "$file"
    done
    for file in "${untracked_files[@]}"; do
      printf -- '- `untracked`: `%s`\n' "$file"
    done
    printf '\nSuggested PR body:\n\n```text\n'
    printf 'Landing scope: %s\n' "$batch_name"
    printf 'Group: %s\n' "$batch_name"
    printf 'Focus: %s\n' "$focus"
    printf 'Handoff artifacts: note=%s memo=%s\n' "$artifact_note" "$artifact_memo"
    printf 'Files: %d total, %d tracked-modified, %d untracked\n' "$(( ${#tracked_files[@]} + ${#untracked_files[@]} ))" "${#tracked_files[@]}" "${#untracked_files[@]}"
    printf '```\n'
    return 0
  done < <(resolve_outside_batch_groups)

  echo "Unknown outside landing batch: ${selected_name_raw}" >&2
  return 1
}

collect_outside_landing_batch_state() {
  local selected_name_raw="$1"
  local selected_name=""
  local name focus files_csv file
  local -a group_files=()

  OUTSIDE_LANDING_BATCH_FOUND="0"
  OUTSIDE_LANDING_BATCH_NAME=""
  OUTSIDE_LANDING_BATCH_FOCUS=""
  OUTSIDE_LANDING_BATCH_TRACKED_FILES=()
  OUTSIDE_LANDING_BATCH_UNTRACKED_FILES=()

  collect_outside_batch_changes
  selected_name="$(normalize_outside_landing_batch_selection "$selected_name_raw")"

  while IFS='|' read -r name focus files_csv; do
    [ -n "$name" ] || continue
    if [ "$name" != "$selected_name" ]; then
      continue
    fi

    OUTSIDE_LANDING_BATCH_NAME="$(resolve_outside_landing_batch_name "$name")"
    OUTSIDE_LANDING_BATCH_FOCUS="$focus"
    IFS=';' read -r -a group_files <<< "$files_csv"
    for file in "${group_files[@]}"; do
      [ -n "$file" ] || continue
      if printf '%s\n' "${OUTSIDE_BATCH_TRACKED_MODIFIED_FILES[@]}" | grep -Fxq "$file"; then
        OUTSIDE_LANDING_BATCH_TRACKED_FILES+=("$file")
      elif printf '%s\n' "${OUTSIDE_BATCH_UNTRACKED_FILES[@]}" | grep -Fxq "$file"; then
        OUTSIDE_LANDING_BATCH_UNTRACKED_FILES+=("$file")
      fi
    done

    if [ "${#OUTSIDE_LANDING_BATCH_TRACKED_FILES[@]}" -gt 0 ] || [ "${#OUTSIDE_LANDING_BATCH_UNTRACKED_FILES[@]}" -gt 0 ]; then
      OUTSIDE_LANDING_BATCH_FOUND="1"
    fi
    return 0
  done < <(resolve_outside_batch_groups)
}

resolve_next_pending_outside_batch_group_name() {
  local name focus files_csv file
  local -a matched_paths=()
  local -a group_files=()

  collect_outside_batch_changes

  while IFS='|' read -r name focus files_csv; do
    [ -n "$name" ] || continue
    matched_paths=()
    IFS=';' read -r -a group_files <<< "$files_csv"
    for file in "${group_files[@]}"; do
      [ -n "$file" ] || continue
      if printf '%s\n' "${OUTSIDE_BATCH_TRACKED_MODIFIED_FILES[@]}" | grep -Fxq "$file" || \
         printf '%s\n' "${OUTSIDE_BATCH_UNTRACKED_FILES[@]}" | grep -Fxq "$file"; then
        matched_paths+=("$file")
      fi
    done
    if [ "${#matched_paths[@]}" -eq 0 ]; then
      continue
    fi
    if ! note_manifest_has_recorded_output "outside-batches" "outside-batch" "$name"; then
      printf '%s\n' "$name"
      return 0
    fi
  done < <(resolve_outside_batch_groups)

  return 1
}

resolve_first_matched_outside_batch_group_name() {
  local name focus files_csv file
  local -a group_files=()

  collect_outside_batch_changes

  while IFS='|' read -r name focus files_csv; do
    [ -n "$name" ] || continue
    IFS=';' read -r -a group_files <<< "$files_csv"
    for file in "${group_files[@]}"; do
      [ -n "$file" ] || continue
      if printf '%s\n' "${OUTSIDE_BATCH_TRACKED_MODIFIED_FILES[@]}" | grep -Fxq "$file" || \
         printf '%s\n' "${OUTSIDE_BATCH_UNTRACKED_FILES[@]}" | grep -Fxq "$file"; then
        printf '%s\n' "$name"
        return 0
      fi
    done
  done < <(resolve_outside_batch_groups)

  return 1
}

resolve_next_pending_outside_landing_batch_group_name() {
  local name focus files_csv file
  local -a group_files=()

  collect_outside_batch_changes

  while IFS='|' read -r name focus files_csv; do
    [ -n "$name" ] || continue
    IFS=';' read -r -a group_files <<< "$files_csv"
    for file in "${group_files[@]}"; do
      [ -n "$file" ] || continue
      if printf '%s\n' "${OUTSIDE_BATCH_TRACKED_MODIFIED_FILES[@]}" | grep -Fxq "$file" || \
         printf '%s\n' "${OUTSIDE_BATCH_UNTRACKED_FILES[@]}" | grep -Fxq "$file"; then
        if ! outside_landing_draft_manifest_has_recorded_output "$name"; then
          printf '%s\n' "$name"
          return 0
        fi
        break
      fi
    done
  done < <(resolve_outside_batch_groups)

  return 1
}

resolve_outside_batch_group_focus_file() {
  local selected_name="$1"
  local name focus files_csv file
  local -a group_files=()

  collect_outside_batch_changes

  while IFS='|' read -r name focus files_csv; do
    [ -n "$name" ] || continue
    if [ "$name" != "$selected_name" ]; then
      continue
    fi
    IFS=';' read -r -a group_files <<< "$files_csv"
    for file in "${group_files[@]}"; do
      [ -n "$file" ] || continue
      if printf '%s\n' "${OUTSIDE_BATCH_TRACKED_MODIFIED_FILES[@]}" | grep -Fxq "$file" || \
         printf '%s\n' "${OUTSIDE_BATCH_UNTRACKED_FILES[@]}" | grep -Fxq "$file"; then
        printf '%s\n' "$file"
        return 0
      fi
    done
  done < <(resolve_outside_batch_groups)

  return 1
}

emit_outside_batch_group_note_points_for_name() {
  local name="$1"

  case "$name" in
    frontend-runtime)
      printf '%s\n' \
        'keeps browser runtime changes grouped as one landing slice before backend or exam-content follow-ups' \
        'treats terminal, dashboard, results, and frontend behavior docs as one review surface'
      ;;
    facilitator-runtime)
      printf '%s\n' \
        'keeps facilitator package, runtime routes, services, redis handling, and lifecycle tests grouped as one landing slice' \
        'treats backend runtime hardening and facilitator-side validation as one subsystem review surface'
      ;;
    exam-content)
      printf '%s\n' \
        'keeps exam assets, validators, answers, and labs metadata grouped as one content landing slice' \
        'treats CKA assessment text and validator hardening as one review surface separate from runtime code'
      ;;
    infra-runtime)
      printf '%s\n' \
        'keeps compose, jumphost, cluster, nginx, remote desktop, and container-runtime changes grouped as one infra landing slice' \
        'treats runtime environment orchestration and podman smoke coverage as one subsystem handoff'
      ;;
    rollout-docs)
      printf '%s\n' \
        'keeps top-level rollout and installation docs grouped as one landing slice after runtime changes are understood' \
        'treats operator-facing setup and rollout guidance as one documentation handoff surface'
      ;;
    *)
      printf '%s\n' \
        'review the selected outside-batch group as a single landing slice' \
        'treat the selected outside-batch group as one subsystem handoff unit'
      ;;
  esac
}

default_outside_batch_note_write_path() {
  local selected_name="$1"
  printf '%s\n' ".artifacts/review-notes/outside-batches-${selected_name}.txt"
}

default_outside_batch_memo_write_path() {
  printf '%s\n' ".artifacts/review-memos/outside-batches-outside-batch-memo.txt"
}

default_outside_landing_draft_write_path() {
  local selected_name="$1"
  printf '.artifacts/review-drafts/%s.md\n' "$selected_name"
}

resolve_next_untracked_group_name() {
  local batch="$1"
  local name focus files_csv file

  compute_batch_status "$batch"

  while IFS='|' read -r name focus files_csv; do
    [ -n "$name" ] || continue
    IFS=';' read -r -a group_files <<< "$files_csv"
    for file in "${group_files[@]}"; do
      [ -n "$file" ] || continue
      if printf '%s\n' "${BATCH_STATUS_UNTRACKED_FILES[@]}" | grep -Fxq "$file"; then
        printf '%s\n' "$name"
        return 0
      fi
    done
  done < <(emit_untracked_group_definitions_for_batch "$batch")

  return 1
}

resolve_next_pending_untracked_group_name() {
  local batch="$1"
  local name focus files_csv

  while IFS='|' read -r name focus files_csv; do
    [ -n "$name" ] || continue
    if ! note_manifest_has_recorded_output "$batch" "untracked" "$name"; then
      if resolve_untracked_group_focus_file "$batch" "$name" >/dev/null 2>&1; then
        printf '%s\n' "$name"
        return 0
      fi
    fi
  done < <(emit_untracked_group_definitions_for_batch "$batch")

  return 1
}

resolve_untracked_group_focus_file() {
  local batch="$1"
  local selected_name="$2"
  local name focus files_csv file

  compute_batch_status "$batch"

  while IFS='|' read -r name focus files_csv; do
    [ -n "$name" ] || continue
    if [ "$name" != "$selected_name" ]; then
      continue
    fi
    IFS=';' read -r -a group_files <<< "$files_csv"
    for file in "${group_files[@]}"; do
      [ -n "$file" ] || continue
      if printf '%s\n' "${BATCH_STATUS_UNTRACKED_FILES[@]}" | grep -Fxq "$file"; then
        printf '%s\n' "$file"
        return 0
      fi
    done
  done < <(emit_untracked_group_definitions_for_batch "$batch")

  return 1
}

resolve_first_unmapped_untracked_file() {
  local batch="$1"
  local file
  local -A grouped_files=()

  compute_batch_status "$batch"

  while IFS='|' read -r _name _focus files_csv; do
    [ -n "$files_csv" ] || continue
    IFS=';' read -r -a group_files <<< "$files_csv"
    for file in "${group_files[@]}"; do
      [ -n "$file" ] || continue
      grouped_files["$file"]=1
    done
  done < <(emit_untracked_group_definitions_for_batch "$batch")

  for file in "${BATCH_STATUS_UNTRACKED_FILES[@]}"; do
    if [ -z "${grouped_files[$file]:-}" ]; then
      printf '%s\n' "$file"
      return 0
    fi
  done

  return 1
}

emit_subchange_lines_for_file() {
  local batch="$1"
  local file="$2"

  case "${batch}:${file}" in
    batch-2:scripts/verify/cka-005-isolated-env-e2e.sh)
      printf '%s\n' \
        "${batch} | SUBCHANGE | tracked-modified | name=bounded-wait-guards | file=${file} | lines=7-129 | focus=retry budgets and bounded wait helpers" \
        "${batch} | SUBCHANGE | tracked-modified | name=stack-reset-recreate | file=${file} | lines=152 | focus=force-recreate compose startup" \
        "${batch} | SUBCHANGE | tracked-modified | name=isolated-dns-precheck-hardening | file=${file} | lines=190-199 | focus=dns-check preflight and SERVFAIL acceptance" \
        "${batch} | SUBCHANGE | tracked-modified | name=post-fix-verification-retry | file=${file} | lines=344-350 | focus=retry final DNS and HTTP verification"
      ;;
    *)
      printf '%s\n' \
        "${batch} | SUBCHANGE | tracked-modified | name=full-file-review | file=${file} | lines=full-file | focus=no-curated-subchange-map"
      ;;
  esac
}

emit_untracked_group_definitions_for_batch() {
  local batch="$1"

  case "$batch" in
    batch-1)
      printf '%s\n' \
        'lifecycle-api-tests|facilitator API and lifecycle negative-path coverage|facilitator/tests/app.test.js;facilitator/tests/examService.test.js' \
        'state-validation-tests|redis state and validator coverage|facilitator/tests/redisClient.test.js;facilitator/tests/validators.test.js'
      ;;
    batch-2)
      printf '%s\n' \
        'regression-suites|cka regression suites and aggregate runner|scripts/verify/cka-003-dedicated-dns-e2e.sh;scripts/verify/cka-004-cluster-dns-e2e.sh;scripts/verify/run-cka-2026-regressions.sh' \
        'diagnostics-runtime|diagnostics collector, pack, and renderer core|scripts/verify/collect-cka-2026-diagnostics.sh;scripts/verify/pack-cka-2026-diagnostics.sh;scripts/verify/render-cka-2026-summary-markdown.sh' \
        'diagnostics-contracts|diagnostics contract smokes and contract runner|scripts/verify/cka-2026-diagnostics-collector-smoke.sh;scripts/verify/cka-2026-diagnostics-pack-smoke.sh;scripts/verify/cka-2026-summary-renderer-smoke.sh;scripts/verify/run-verify-contract-smokes.sh' \
        'review-runner|review batch runner entrypoint, landing summary/draft renderers, handoff exporter, and export contract smoke|scripts/verify/run-review-batch-checks.sh;scripts/verify/render-review-landing-summary.sh;scripts/verify/render-review-landing-drafts.sh;scripts/verify/pack-review-batch-handoff.sh;scripts/verify/review-batch-handoff-pack-smoke.sh'
      ;;
    batch-3)
      printf '%s\n' \
        'browser-runtime|playwright browser smoke runtime and package wiring|scripts/verify/browser-ui-smoke.mjs;scripts/verify/package.json' \
        'browser-contract-docs|browser scenario contract and verify docs alignment|scripts/verify/browser-ui-scenario-contract-smoke.sh;scripts/verify/README.md'
      ;;
    batch-4)
      printf '%s\n' \
        'default-ci|default GitHub Actions CI workflow wiring|.github/workflows/ci.yml' \
        'cka-regression-workflow|self-hosted CKA regression workflow and contract smoke|.github/workflows/cka-2026-regressions.yml;scripts/verify/cka-2026-workflow-contract-smoke.sh' \
        'review-batch-workflow|manual review-batch workflow and contract smoke|.github/workflows/review-batch-checks.yml;scripts/verify/review-batch-workflow-contract-smoke.sh'
      ;;
    batch-5)
      printf '%s\n' \
        'review-docs|audit report and review inventory docs|docs/reports/codebase-audit-2026-04-10.md;docs/reports/review-inventory-2026-04-10.md'
      ;;
  esac
}

emit_untracked_group_note_points_for_name() {
  local batch="$1"
  local name="$2"

  case "${batch}:${name}" in
    batch-1:lifecycle-api-tests)
      printf '%s\n' \
        'keeps the app route mapping and examService lifecycle failure-path tests in one landing slice' \
        'treats API error mapping and async evaluation failure coverage as one review surface before state helpers'
      ;;
    batch-1:state-validation-tests)
      printf '%s\n' \
        'keeps redis client edge cases and validator coverage together as one state-safety slice' \
        'treats stored metadata handling and request validation hardening as one landing surface'
      ;;
    batch-2:regression-suites)
      printf '%s\n' \
        'keeps the dedicated cka-003 and cka-004 regression entrypoints grouped with the aggregate runner' \
        'treats suite-level regression scripts as one landing surface before diagnostics helpers and contract smokes' \
        'preserves the runner-to-suite contract for local CKA 2026 execution'
      ;;
    batch-2:diagnostics-runtime)
      printf '%s\n' \
        'groups the raw diagnostics collector, archive packer, and markdown renderer as one runtime surface' \
        'keeps bundle collection, packing, and summary rendering reviewable before workflow wiring changes'
      ;;
    batch-2:diagnostics-contracts)
      printf '%s\n' \
        'groups the synthetic collector, pack, and renderer smokes with the top-level contract runner' \
        'keeps diagnostics contract coverage aligned with the runtime helpers they protect'
      ;;
    batch-2:review-runner)
      printf '%s\n' \
        'isolates the review batch runner entrypoint, landing summary/draft renderers, handoff exporter, and export pack smoke as one landing unit' \
        'keeps review orchestration, landing-plan summarization, commit-draft rendering, artifact indexing, export packaging, and export contract coverage separate from regression runtime and diagnostics packaging code'
      ;;
    batch-3:browser-runtime)
      printf '%s\n' \
        'keeps the Playwright fixture runtime and its npm wiring in one landing slice' \
        'treats executable browser smoke behavior and package entrypoints as one review surface before docs-only alignment'
      ;;
    batch-3:browser-contract-docs)
      printf '%s\n' \
        'keeps the browser scenario contract script aligned with the verify README in one landing slice' \
        'treats documented browser coverage and lightweight contract wiring as one handoff unit after the runtime files'
      ;;
    batch-4:default-ci)
      printf '%s\n' \
        'isolates the default CI workflow so lightweight PR-path wiring can land independently of manual workflow changes' \
        'treats contract smoke job wiring and default CI ordering as one landing surface'
      ;;
    batch-4:cka-regression-workflow)
      printf '%s\n' \
        'keeps the self-hosted regression workflow aligned with its contract smoke in one landing slice' \
        'treats regression inputs, diagnostics publication, and workflow contract expectations as one review surface'
      ;;
    batch-4:review-batch-workflow)
      printf '%s\n' \
        'keeps the manual review-batch workflow aligned with its contract smoke in one landing slice' \
        'treats matrix planning, conditional installs, and workflow contract coverage as one handoff unit'
      ;;
    batch-5:review-docs)
      printf '%s\n' \
        'keeps the audit report and review inventory aligned in one documentation landing slice' \
        'treats rollout guidance and landing manifests as one handoff unit after code-facing batches are summarized'
      ;;
    *)
      printf '%s\n' 'review the selected untracked landing group as a single handoff slice'
      ;;
  esac
}

emit_subchange_note_points_for_name() {
  local batch="$1"
  local file="$2"
  local name="$3"

  case "${batch}:${file}:${name}" in
    batch-2:scripts/verify/cka-005-isolated-env-e2e.sh:bounded-wait-guards)
      printf '%s\n' \
        'adds explicit attempt-budget knobs for HTTP, health, exam-status, evaluation, and cleanup waits' \
        'replaces unbounded polling loops with bounded retries that fail fast on timeout' \
        'surfaces last observed status or message in timeout output to speed up triage'
      ;;
    batch-2:scripts/verify/cka-005-isolated-env-e2e.sh:stack-reset-recreate)
      printf '%s\n' \
        'forces compose startup to recreate containers during stack reset' \
        'reduces stale-container drift between repeated local regression runs'
      ;;
    batch-2:scripts/verify/cka-005-isolated-env-e2e.sh:isolated-dns-precheck-hardening)
      printf '%s\n' \
        'switches isolated DNS precheck to the existing dns-check pod instead of a transient probe pod' \
        'accepts SERVFAIL alongside earlier refusal errors so the failure contract matches observed behavior'
      ;;
    batch-2:scripts/verify/cka-005-isolated-env-e2e.sh:post-fix-verification-retry)
      printf '%s\n' \
        'wraps the final DNS and HTTP verification in bounded retries after the fix is applied' \
        'reduces false negatives caused by short post-fix propagation delays'
      ;;
    *)
      printf '%s\n' 'review the selected subchange as a single landing slice'
      ;;
  esac
}

resolve_first_curated_subchange_name() {
  local batch="$1"
  local file="$2"

  emit_subchange_lines_for_file "$batch" "$file" \
    | awk -F' \\| ' '
        /\| SUBCHANGE \|/ {
          for (i = 1; i <= NF; i++) {
            if ($i ~ /^name=/) {
              sub(/^name=/, "", $i)
              print $i
              exit
            }
          }
        }
      '
}

extract_subchange_field() {
  local line="$1"
  local key="$2"

  awk -F' \\| ' -v key="$key" '
    {
      for (i = 1; i <= NF; i++) {
        if ($i ~ ("^" key "=")) {
          sub("^" key "=", "", $i)
          print $i
          exit
        }
      }
    }
  ' <<< "$line"
}

parse_line_range_bounds() {
  local line_range="$1"
  local __start_var="$2"
  local __end_var="$3"
  local start end

  if [ "$line_range" = "full-file" ]; then
    printf -v "$__start_var" '%s' "1"
    printf -v "$__end_var" '%s' "999999999"
    return 0
  fi

  if [[ "$line_range" == *-* ]]; then
    start="${line_range%%-*}"
    end="${line_range##*-}"
  else
    start="$line_range"
    end="$line_range"
  fi

  printf -v "$__start_var" '%s' "$start"
  printf -v "$__end_var" '%s' "$end"
}

line_ranges_overlap() {
  local start_a="$1"
  local end_a="$2"
  local start_b="$3"
  local end_b="$4"

  if [ "$end_a" -lt "$start_b" ] || [ "$end_b" -lt "$start_a" ]; then
    return 1
  fi

  return 0
}

print_batch_diff() {
  local batch="$1"
  local filter="${2:-tracked-modified}"
  local file numstat additions deletions path
  local -a files=()

  validate_diff_filter "$filter"
  compute_batch_status "$batch"

  case "$filter" in
    tracked-modified)
      files=("${BATCH_STATUS_TRACKED_MODIFIED_FILES[@]}")
      ;;
  esac

  printf '%s | diff-subset=%s | count=%s\n' "$batch" "$filter" "${#files[@]}"

  for file in "${files[@]}"; do
    numstat="$(git -C "$ROOT_DIR" diff --numstat -- "$file" | head -n 1 || true)"
    if [ -n "$numstat" ]; then
      IFS=$'\t' read -r additions deletions path <<< "$numstat"
    else
      additions="0"
      deletions="0"
      path="$file"
    fi
    printf '%s | DIFFSTAT | %s | additions=%s | deletions=%s | %s\n' \
      "$batch" \
      "$filter" \
      "$additions" \
      "$deletions" \
      "$path"
  done
}

print_batch_hunks() {
  local batch="$1"
  local filter="${2:-tracked-modified}"
  local file diff_output hunk_count total_hunks
  local header new_part new_start new_count new_end scope
  local -a files=()

  validate_hunk_filter "$filter"
  compute_batch_status "$batch"

  case "$filter" in
    tracked-modified)
      files=("${BATCH_STATUS_TRACKED_MODIFIED_FILES[@]}")
      ;;
  esac

  total_hunks=0
  for file in "${files[@]}"; do
    diff_output="$(git -C "$ROOT_DIR" diff --unified=0 -- "$file" || true)"
    hunk_count="$(printf '%s\n' "$diff_output" | grep -c '^@@ ' || true)"
    total_hunks=$((total_hunks + hunk_count))
  done

  printf '%s | hunk-subset=%s | file-count=%s | hunk-count=%s\n' \
    "$batch" \
    "$filter" \
    "${#files[@]}" \
    "$total_hunks"

  for file in "${files[@]}"; do
    diff_output="$(git -C "$ROOT_DIR" diff --unified=0 -- "$file" || true)"
    while IFS= read -r header; do
      [ -n "$header" ] || continue
      new_part="${header#*+}"
      new_part="${new_part%% @@*}"
      scope="${header##*@@ }"
      if [ "$scope" = "$header" ]; then
        scope="(scope unavailable)"
      fi
      if [[ "$new_part" == *,* ]]; then
        new_start="${new_part%%,*}"
        new_count="${new_part##*,}"
      else
        new_start="$new_part"
        new_count="1"
      fi
      if [ "$new_count" -le 0 ]; then
        new_end="$new_start"
      else
        new_end="$((new_start + new_count - 1))"
      fi
      if [ "$new_start" = "$new_end" ]; then
        printf '%s | HUNK | %s | file=%s | lines=%s | scope=%s\n' \
          "$batch" \
          "$filter" \
          "$file" \
          "$new_start" \
          "$scope"
      else
        printf '%s | HUNK | %s | file=%s | lines=%s-%s | scope=%s\n' \
          "$batch" \
          "$filter" \
          "$file" \
          "$new_start" \
          "$new_end" \
          "$scope"
      fi
    done < <(printf '%s\n' "$diff_output" | grep '^@@ ' || true)
  done
}

print_batch_subchanges() {
  local batch="$1"
  local filter="${2:-tracked-modified}"
  local selected_name="${3:-}"
  local detail_mode="${4:-0}"
  local file line line_file line_range line_name
  local diff_output header new_part new_start new_count new_end scope
  local -a files=()
  local -a subchange_lines=()

  validate_subchange_filter "$filter"
  compute_batch_status "$batch"

  case "$filter" in
    tracked-modified)
      files=("${BATCH_STATUS_TRACKED_MODIFIED_FILES[@]}")
      ;;
  esac

  for file in "${files[@]}"; do
    while IFS= read -r line; do
      [ -n "$line" ] || continue
      if [ -n "$selected_name" ] && [[ "$line" != *" | name=${selected_name} | "* ]]; then
        continue
      fi
      subchange_lines+=("$line")
    done < <(emit_subchange_lines_for_file "$batch" "$file")
  done

  if [ -n "$selected_name" ]; then
    if [ "${#subchange_lines[@]}" -eq 0 ] && [ "${#files[@]}" -gt 0 ]; then
      echo "No subchange named '${selected_name}' found for ${batch} (${filter})" >&2
      return 1
    fi
    printf '%s | subchange-subset=%s | name=%s | file-count=%s | subchange-count=%s\n' \
      "$batch" \
      "$filter" \
      "$selected_name" \
      "${#files[@]}" \
      "${#subchange_lines[@]}"
  else
    printf '%s | subchange-subset=%s | file-count=%s | subchange-count=%s\n' \
      "$batch" \
      "$filter" \
      "${#files[@]}" \
      "${#subchange_lines[@]}"
  fi

  for line in "${subchange_lines[@]}"; do
    printf '%s\n' "$line"
  done

  if [ "$detail_mode" != "1" ]; then
    return 0
  fi

  for line in "${subchange_lines[@]}"; do
    line_name="$(extract_subchange_field "$line" "name")"
    line_file="$(extract_subchange_field "$line" "file")"
    line_range="$(extract_subchange_field "$line" "lines")"
    diff_output="$(git -C "$ROOT_DIR" diff --unified=0 -- "$line_file" || true)"

    while IFS= read -r header; do
      [ -n "$header" ] || continue
      new_part="${header#*+}"
      new_part="${new_part%% @@*}"
      scope="${header##*@@ }"
      if [ "$scope" = "$header" ]; then
        scope="(scope unavailable)"
      fi
      if [[ "$new_part" == *,* ]]; then
        new_start="${new_part%%,*}"
        new_count="${new_part##*,}"
      else
        new_start="$new_part"
        new_count="1"
      fi
      if [ "$new_count" -le 0 ]; then
        new_end="$new_start"
      else
        new_end="$((new_start + new_count - 1))"
      fi

      local range_start range_end
      parse_line_range_bounds "$line_range" range_start range_end
      if ! line_ranges_overlap "$range_start" "$range_end" "$new_start" "$new_end"; then
        continue
      fi

      if [ "$new_start" = "$new_end" ]; then
        printf '%s | DETAIL | %s | name=%s | file=%s | lines=%s | scope=%s\n' \
          "$batch" \
          "$filter" \
          "$line_name" \
          "$line_file" \
          "$new_start" \
          "$scope"
      else
        printf '%s | DETAIL | %s | name=%s | file=%s | lines=%s-%s | scope=%s\n' \
          "$batch" \
          "$filter" \
          "$line_name" \
          "$line_file" \
          "$new_start" \
          "$new_end" \
          "$scope"
      fi
    done < <(printf '%s\n' "$diff_output" | grep '^@@ ' || true)
  done
}

print_batch_note() {
  local batch="$1"
  local filter="${2:-tracked-modified}"
  local selected_name="$3"
  local file line point group_name group_focus files_csv
  local -a files=()
  local -a subchange_lines=()
  local -a note_points=()
  local -a matched_files=()

  validate_note_filter "$filter"
  if [ -z "$selected_name" ]; then
    echo "--note requires --name <subchange-or-group>" >&2
    return 1
  fi

  compute_batch_status "$batch"

  case "$filter" in
    tracked-modified)
      files=("${BATCH_STATUS_TRACKED_MODIFIED_FILES[@]}")
      for file in "${files[@]}"; do
        while IFS= read -r line; do
          [ -n "$line" ] || continue
          if [[ "$line" != *" | name=${selected_name} | "* ]]; then
            continue
          fi
          subchange_lines+=("$line")
          while IFS= read -r point; do
            [ -n "$point" ] || continue
            note_points+=("$point")
          done < <(emit_subchange_note_points_for_name "$batch" "$file" "$selected_name")
        done < <(emit_subchange_lines_for_file "$batch" "$file")
      done

      if [ "${#subchange_lines[@]}" -eq 0 ]; then
        echo "No subchange named '${selected_name}' found for ${batch} (${filter})" >&2
        return 1
      fi

      printf '%s | note-subset=%s | name=%s | file-count=%s | note-point-count=%s\n' \
        "$batch" \
        "$filter" \
        "$selected_name" \
        "${#files[@]}" \
        "${#note_points[@]}"

      for line in "${subchange_lines[@]}"; do
        printf '%s | NOTE | %s\n' "$batch" "${line#${batch} | SUBCHANGE | }"
      done
      ;;
    untracked)
      files=("${BATCH_STATUS_UNTRACKED_FILES[@]}")
      while IFS='|' read -r group_name group_focus files_csv; do
        [ -n "$group_name" ] || continue
        if [ "$group_name" != "$selected_name" ]; then
          continue
        fi
        IFS=';' read -r -a group_files <<< "$files_csv"
        for file in "${group_files[@]}"; do
          [ -n "$file" ] || continue
          if printf '%s\n' "${files[@]}" | grep -Fxq "$file"; then
            matched_files+=("$file")
            subchange_lines+=("${batch} | NOTE | ${filter} | name=${selected_name} | file=${file} | lines=full-file | focus=${group_focus}")
          fi
        done
        while IFS= read -r point; do
          [ -n "$point" ] || continue
          note_points+=("$point")
        done < <(emit_untracked_group_note_points_for_name "$batch" "$selected_name")
      done < <(emit_untracked_group_definitions_for_batch "$batch")

      if [ "${#matched_files[@]}" -eq 0 ]; then
        echo "No untracked group named '${selected_name}' found for ${batch} (${filter})" >&2
        return 1
      fi

      printf '%s | note-subset=%s | name=%s | file-count=%s | note-point-count=%s\n' \
        "$batch" \
        "$filter" \
        "$selected_name" \
        "${#matched_files[@]}" \
        "${#note_points[@]}"

      for line in "${subchange_lines[@]}"; do
        printf '%s\n' "$line"
      done
      ;;
  esac

  for point in "${note_points[@]}"; do
    printf '%s | NOTE-POINT | %s | name=%s | point=%s\n' \
      "$batch" \
      "$filter" \
      "$selected_name" \
      "$point"
  done
}

print_batch_memo() {
  local batch="$1"
  local filter="${2:-tracked-modified}"
  local file line point group_name group_focus files_csv
  local section_name file_path line_range section_focus
  local -a files=()
  local -a subchange_lines=()
  local -a memo_points=()
  local -a matched_files=()

  validate_memo_filter "$filter"
  compute_batch_status "$batch"

  case "$filter" in
    tracked-modified)
      files=("${BATCH_STATUS_TRACKED_MODIFIED_FILES[@]}")
      for file in "${files[@]}"; do
        while IFS= read -r line; do
          [ -n "$line" ] || continue
          subchange_lines+=("$line")
          section_name="$(extract_subchange_field "$line" "name")"
          while IFS= read -r point; do
            [ -n "$point" ] || continue
            memo_points+=("${section_name}|${point}")
          done < <(emit_subchange_note_points_for_name "$batch" "$file" "$section_name")
        done < <(emit_subchange_lines_for_file "$batch" "$file")
      done
      ;;
    untracked)
      files=("${BATCH_STATUS_UNTRACKED_FILES[@]}")
      while IFS='|' read -r group_name group_focus files_csv; do
        [ -n "$group_name" ] || continue
        matched_files=()
        IFS=';' read -r -a group_files <<< "$files_csv"
        for file in "${group_files[@]}"; do
          [ -n "$file" ] || continue
          if printf '%s\n' "${files[@]}" | grep -Fxq "$file"; then
            matched_files+=("$file")
            subchange_lines+=("${batch} | SUBCHANGE | ${filter} | name=${group_name} | file=${file} | lines=full-file | focus=${group_focus}")
          fi
        done
        if [ "${#matched_files[@]}" -eq 0 ]; then
          continue
        fi
        while IFS= read -r point; do
          [ -n "$point" ] || continue
          memo_points+=("${group_name}|${point}")
        done < <(emit_untracked_group_note_points_for_name "$batch" "$group_name")
      done < <(emit_untracked_group_definitions_for_batch "$batch")
      ;;
  esac

  printf '%s | memo-subset=%s | file-count=%s | section-count=%s | point-count=%s\n' \
    "$batch" \
    "$filter" \
    "${#files[@]}" \
    "${#subchange_lines[@]}" \
    "${#memo_points[@]}"

  for line in "${subchange_lines[@]}"; do
    section_name="$(extract_subchange_field "$line" "name")"
    file_path="$(extract_subchange_field "$line" "file")"
    line_range="$(extract_subchange_field "$line" "lines")"
    section_focus="$(extract_subchange_field "$line" "focus")"
    printf '%s | MEMO-SECTION | %s | name=%s | file=%s | lines=%s | focus=%s\n' \
      "$batch" \
      "$filter" \
      "$section_name" \
      "$file_path" \
      "$line_range" \
      "$section_focus"
  done

  for point in "${memo_points[@]}"; do
    section_name="${point%%|*}"
    point="${point#*|}"
    printf '%s | MEMO-POINT | %s | name=%s | point=%s\n' \
      "$batch" \
      "$filter" \
      "$section_name" \
      "$point"
  done
}

print_outside_batch_note() {
  local selected_name="$1"
  local name focus files_csv file point
  local -a group_files=()
  local -a matched_files=()
  local -a note_lines=()
  local -a note_points=()

  if [ -z "$selected_name" ]; then
    echo "--outside-batch-note requires --name <group>" >&2
    return 1
  fi

  collect_outside_batch_changes

  while IFS='|' read -r name focus files_csv; do
    [ -n "$name" ] || continue
    if [ "$name" != "$selected_name" ]; then
      continue
    fi
    IFS=';' read -r -a group_files <<< "$files_csv"
    for file in "${group_files[@]}"; do
      [ -n "$file" ] || continue
      if printf '%s\n' "${OUTSIDE_BATCH_TRACKED_MODIFIED_FILES[@]}" | grep -Fxq "$file"; then
        matched_files+=("$file")
        note_lines+=("outside-batches | NOTE | outside-batch | name=${selected_name} | file=${file} | state=tracked-modified | lines=full-file | focus=${focus}")
      elif printf '%s\n' "${OUTSIDE_BATCH_UNTRACKED_FILES[@]}" | grep -Fxq "$file"; then
        matched_files+=("$file")
        note_lines+=("outside-batches | NOTE | outside-batch | name=${selected_name} | file=${file} | state=untracked | lines=full-file | focus=${focus}")
      fi
    done
    while IFS= read -r point; do
      [ -n "$point" ] || continue
      note_points+=("$point")
    done < <(emit_outside_batch_group_note_points_for_name "$selected_name")
  done < <(resolve_outside_batch_groups)

  if [ "${#matched_files[@]}" -eq 0 ]; then
    echo "No outside-batch group named '${selected_name}' currently matches repo drift" >&2
    return 1
  fi

  printf '%s | note-subset=outside-batch | name=%s | file-count=%s | note-point-count=%s\n' \
    "outside-batches" \
    "$selected_name" \
    "${#matched_files[@]}" \
    "${#note_points[@]}"

  for line in "${note_lines[@]}"; do
    printf '%s\n' "$line"
  done

  for point in "${note_points[@]}"; do
    printf '%s | NOTE-POINT | outside-batch | name=%s | point=%s\n' \
      "outside-batches" \
      "$selected_name" \
      "$point"
  done
}

print_outside_batch_memo() {
  local name focus files_csv file point
  local -a group_files=()
  local -a subchange_lines=()
  local -a memo_points=()
  local -a matched_files=()
  local total_files=0

  collect_outside_batch_changes

  while IFS='|' read -r name focus files_csv; do
    [ -n "$name" ] || continue
    matched_files=()
    IFS=';' read -r -a group_files <<< "$files_csv"
    for file in "${group_files[@]}"; do
      [ -n "$file" ] || continue
      if printf '%s\n' "${OUTSIDE_BATCH_TRACKED_MODIFIED_FILES[@]}" | grep -Fxq "$file"; then
        matched_files+=("$file")
        subchange_lines+=("outside-batches | SUBCHANGE | outside-batch | name=${name} | file=${file} | lines=full-file | focus=${focus}")
      elif printf '%s\n' "${OUTSIDE_BATCH_UNTRACKED_FILES[@]}" | grep -Fxq "$file"; then
        matched_files+=("$file")
        subchange_lines+=("outside-batches | SUBCHANGE | outside-batch | name=${name} | file=${file} | lines=full-file | focus=${focus}")
      fi
    done
    if [ "${#matched_files[@]}" -eq 0 ]; then
      continue
    fi
    total_files=$((total_files + ${#matched_files[@]}))
    while IFS= read -r point; do
      [ -n "$point" ] || continue
      memo_points+=("${name}|${point}")
    done < <(emit_outside_batch_group_note_points_for_name "$name")
  done < <(resolve_outside_batch_groups)

  printf '%s | memo-subset=outside-batch | file-count=%s | section-count=%s | point-count=%s\n' \
    "outside-batches" \
    "$total_files" \
    "${#subchange_lines[@]}" \
    "${#memo_points[@]}"

  for line in "${subchange_lines[@]}"; do
    printf '%s | MEMO-SECTION | outside-batch | name=%s | file=%s | lines=%s | focus=%s\n' \
      "outside-batches" \
      "$(extract_subchange_field "$line" "name")" \
      "$(extract_subchange_field "$line" "file")" \
      "$(extract_subchange_field "$line" "lines")" \
      "$(extract_subchange_field "$line" "focus")"
  done

  for point in "${memo_points[@]}"; do
    printf '%s | MEMO-POINT | outside-batch | name=%s | point=%s\n' \
      "outside-batches" \
      "${point%%|*}" \
      "${point#*|}"
  done
}

write_output_file() {
  local output_path="$1"
  local output_text="$2"

  mkdir -p "$(dirname "$output_path")"
  printf '%s\n' "$output_text" > "$output_path"
}

append_memo_manifest() {
  local manifest_path="$1"
  local memo_path="$2"
  local filter="$3"
  local bytes="$4"
  shift 4
  local batches_csv=""

  if [ "$#" -gt 0 ]; then
    batches_csv="$(IFS=,; printf '%s' "$*")"
  fi

  mkdir -p "$(dirname "$manifest_path")"
  printf '%s | batches=%s | filter=%s | output=%s | bytes=%s\n' \
    "$(date -Iseconds)" \
    "$batches_csv" \
    "$filter" \
    "$memo_path" \
    "$bytes" \
    >> "$manifest_path"
}

append_note_manifest() {
  local manifest_path="$1"
  local note_path="$2"
  local filter="$3"
  local selected_name="$4"
  local bytes="$5"
  shift 5
  local batches_csv=""

  if [ "$#" -gt 0 ]; then
    batches_csv="$(IFS=,; printf '%s' "$*")"
  fi

  mkdir -p "$(dirname "$manifest_path")"
  printf '%s | batches=%s | filter=%s | name=%s | output=%s | bytes=%s\n' \
    "$(date -Iseconds)" \
    "$batches_csv" \
    "$filter" \
    "$selected_name" \
    "$note_path" \
    "$bytes" \
    >> "$manifest_path"
}

append_outside_landing_draft_manifest() {
  local manifest_path="$1"
  local draft_path="$2"
  local selected_name="$3"
  local bytes="$4"

  mkdir -p "$(dirname "$manifest_path")"
  printf '%s | batches=outside-batches | filter=outside-landing-draft | name=%s | output=%s | bytes=%s\n' \
    "$(date -Iseconds)" \
    "$selected_name" \
    "$draft_path" \
    "$bytes" \
    >> "$manifest_path"
}

extract_memo_manifest_field() {
  local line="$1"
  local key="$2"

  awk -F' \\| ' -v key="$key" '
    NR == 1 {
      if (key == "timestamp") {
        print $1
        exit
      }
      for (i = 1; i <= NF; i++) {
        if ($i ~ ("^" key "=")) {
          sub("^" key "=", "", $i)
          print $i
          exit
        }
      }
    }
  ' <<<"$line"
}

manifest_line_matches_batch() {
  local line="$1"
  local batch="$2"
  local batches

  batches="$(extract_memo_manifest_field "$line" "batches")"
  case ",$batches," in
    *,"$batch",*)
      return 0
      ;;
  esac

  return 1
}

default_note_write_path() {
  local batch="$1"
  local selected_name="$2"
  local filter="${3:-tracked-modified}"

  if [ "$filter" = "tracked-modified" ]; then
    printf '%s\n' ".artifacts/review-notes/${batch}-${selected_name}.txt"
    return 0
  fi

  printf '%s\n' ".artifacts/review-notes/${batch}-${filter}-${selected_name}.txt"
}

default_memo_write_path() {
  local batch="$1"
  local filter="${2:-tracked-modified}"

  printf '%s\n' ".artifacts/review-memos/${batch}-${filter}-memo.txt"
}

note_manifest_has_recorded_output() {
  local batch="$1"
  local filter="$2"
  local selected_name="$3"
  local line batches output_path

  if [ ! -f "$NOTE_MANIFEST_PATH" ]; then
    return 1
  fi

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    if [ "$(extract_memo_manifest_field "$line" "filter")" != "$filter" ]; then
      continue
    fi
    if [ "$(extract_memo_manifest_field "$line" "name")" != "$selected_name" ]; then
      continue
    fi
    if manifest_line_matches_batch "$line" "$batch"; then
      output_path="$(extract_memo_manifest_field "$line" "output")"
      if [ -f "$output_path" ]; then
        return 0
      fi
    fi
  done < <(grep -ve '^$' "$NOTE_MANIFEST_PATH")

  return 1
}

memo_manifest_has_recorded_output() {
  local batch="$1"
  local filter="$2"
  local line batches output_path

  if [ ! -f "$MEMO_MANIFEST_PATH" ]; then
    return 1
  fi

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    if [ "$(extract_memo_manifest_field "$line" "filter")" != "$filter" ]; then
      continue
    fi
    if manifest_line_matches_batch "$line" "$batch"; then
      output_path="$(extract_memo_manifest_field "$line" "output")"
      if [ -f "$output_path" ]; then
        return 0
      fi
    fi
  done < <(grep -ve '^$' "$MEMO_MANIFEST_PATH")

  return 1
}

outside_landing_draft_manifest_has_recorded_output() {
  local selected_name_raw="$1"
  local selected_name=""
  local line output_path

  selected_name="$(normalize_outside_landing_batch_selection "$selected_name_raw")"
  selected_name="$(resolve_outside_landing_batch_name "$selected_name")"

  if [ ! -f "$OUTSIDE_LANDING_DRAFT_MANIFEST_PATH" ]; then
    return 1
  fi

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    if [ "$(extract_memo_manifest_field "$line" "filter")" != "outside-landing-draft" ]; then
      continue
    fi
    if [ "$(extract_memo_manifest_field "$line" "name")" != "$selected_name" ]; then
      continue
    fi
    output_path="$(extract_memo_manifest_field "$line" "output")"
    if [ -f "$output_path" ]; then
      return 0
    fi
  done < <(grep -ve '^$' "$OUTSIDE_LANDING_DRAFT_MANIFEST_PATH")

  return 1
}

resolve_next_curated_subchange_name() {
  local batch="$1"
  local file="$2"
  local filter="${3:-tracked-modified}"
  local line selected_name

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    selected_name="$(extract_subchange_field "$line" "name")"
    if ! note_manifest_has_recorded_output "$batch" "$filter" "$selected_name"; then
      printf '%s\n' "$selected_name"
      return 0
    fi
  done < <(emit_subchange_lines_for_file "$batch" "$file")

  return 1
}

print_note_manifest_show() {
  local output_path="$1"
  local source_label="$2"
  local output_state="missing"
  local line_count="0"
  local byte_count="0"
  local line

  if [ -f "$output_path" ]; then
    output_state="present"
    line_count="$(awk 'END { print NR }' "$output_path")"
    byte_count="$(wc -c < "$output_path" | tr -d '[:space:]')"
  fi

  printf '%s | source=%s | path=%s | state=%s' \
    "NOTE-SHOW" \
    "$source_label" \
    "$output_path" \
    "$output_state"
  if [ "$output_state" = "present" ]; then
    printf ' | lines=%s | bytes=%s\n' "$line_count" "$byte_count"
  else
    printf '\n'
  fi

  if [ "$output_state" != "present" ]; then
    return 0
  fi

  while IFS= read -r line; do
    printf '%s | %s\n' "NOTE-CONTENT" "$line"
  done < "$output_path"
}

print_note_manifest() {
  local latest_only="${1:-0}"
  local show_output="${2:-0}"
  local manifest_path="$NOTE_MANIFEST_PATH"
  local entries="0"
  local manifest_state="missing"
  local line index output_path output_state

  if [ -f "$manifest_path" ]; then
    entries="$(grep -cve '^$' "$manifest_path" || true)"
    if [ "$entries" -gt 0 ]; then
      manifest_state="present"
    else
      manifest_state="empty"
    fi
  fi

  printf '%s | path=%s | entries=%s | state=%s\n' \
    "NOTE-MANIFEST" \
    "$manifest_path" \
    "$entries" \
    "$manifest_state"

  if [ "$manifest_state" != "present" ]; then
    if [ "$latest_only" = "1" ]; then
      printf '%s | state=%s\n' "NOTE-LATEST" "$manifest_state"
    fi
    if [ "$show_output" = "1" ]; then
      printf '%s | source=latest | path= | state=%s\n' "NOTE-SHOW" "$manifest_state"
    fi
    return 0
  fi

  if [ "$latest_only" = "1" ]; then
    line="$(grep -ve '^$' "$manifest_path" | tail -n 1)"
    output_path="$(extract_memo_manifest_field "$line" "output")"
    if [ -f "$output_path" ]; then
      output_state="present"
    else
      output_state="missing"
    fi
    printf '%s | index=%s | timestamp=%s | batches=%s | filter=%s | name=%s | output=%s | bytes=%s | output-state=%s\n' \
      "NOTE-LATEST" \
      "$entries" \
      "$(extract_memo_manifest_field "$line" "timestamp")" \
      "$(extract_memo_manifest_field "$line" "batches")" \
      "$(extract_memo_manifest_field "$line" "filter")" \
      "$(extract_memo_manifest_field "$line" "name")" \
      "$output_path" \
      "$(extract_memo_manifest_field "$line" "bytes")" \
      "$output_state"
    if [ "$show_output" = "1" ]; then
      print_note_manifest_show "$output_path" "latest"
    fi
    return 0
  fi

  index=0
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    index=$((index + 1))
    output_path="$(extract_memo_manifest_field "$line" "output")"
    if [ -f "$output_path" ]; then
      output_state="present"
    else
      output_state="missing"
    fi
    printf '%s | index=%s | timestamp=%s | batches=%s | filter=%s | name=%s | output=%s | bytes=%s | output-state=%s\n' \
      "NOTE-ENTRY" \
      "$index" \
      "$(extract_memo_manifest_field "$line" "timestamp")" \
      "$(extract_memo_manifest_field "$line" "batches")" \
      "$(extract_memo_manifest_field "$line" "filter")" \
      "$(extract_memo_manifest_field "$line" "name")" \
      "$output_path" \
      "$(extract_memo_manifest_field "$line" "bytes")" \
      "$output_state"
  done < <(grep -ve '^$' "$manifest_path")

  if [ "$show_output" = "1" ]; then
    line="$(grep -ve '^$' "$manifest_path" | tail -n 1)"
    output_path="$(extract_memo_manifest_field "$line" "output")"
    print_note_manifest_show "$output_path" "latest"
  fi
}

print_memo_manifest() {
  local latest_only="${1:-0}"
  local show_output="${2:-0}"
  local manifest_path="$MEMO_MANIFEST_PATH"
  local entries="0"
  local manifest_state="missing"
  local line index output_path output_state

  if [ -f "$manifest_path" ]; then
    entries="$(grep -cve '^$' "$manifest_path" || true)"
    if [ "$entries" -gt 0 ]; then
      manifest_state="present"
    else
      manifest_state="empty"
    fi
  fi

  printf '%s | path=%s | entries=%s | state=%s\n' \
    "MEMO-MANIFEST" \
    "$manifest_path" \
    "$entries" \
    "$manifest_state"

  if [ "$manifest_state" != "present" ]; then
    if [ "$latest_only" = "1" ]; then
      printf '%s | state=%s\n' "MEMO-LATEST" "$manifest_state"
    fi
    if [ "$show_output" = "1" ]; then
      printf '%s | source=latest | path= | state=%s\n' "MEMO-SHOW" "$manifest_state"
    fi
    return 0
  fi

  if [ "$latest_only" = "1" ]; then
    line="$(grep -ve '^$' "$manifest_path" | tail -n 1)"
    output_path="$(extract_memo_manifest_field "$line" "output")"
    if [ -f "$output_path" ]; then
      output_state="present"
    else
      output_state="missing"
    fi
    printf '%s | index=%s | timestamp=%s | batches=%s | filter=%s | output=%s | bytes=%s | output-state=%s\n' \
      "MEMO-LATEST" \
      "$entries" \
      "$(extract_memo_manifest_field "$line" "timestamp")" \
      "$(extract_memo_manifest_field "$line" "batches")" \
      "$(extract_memo_manifest_field "$line" "filter")" \
      "$output_path" \
      "$(extract_memo_manifest_field "$line" "bytes")" \
      "$output_state"
    if [ "$show_output" = "1" ]; then
      print_memo_manifest_show "$output_path" "latest"
    fi
    return 0
  fi

  index=0
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    index=$((index + 1))
    output_path="$(extract_memo_manifest_field "$line" "output")"
    if [ -f "$output_path" ]; then
      output_state="present"
    else
      output_state="missing"
    fi
    printf '%s | index=%s | timestamp=%s | batches=%s | filter=%s | output=%s | bytes=%s | output-state=%s\n' \
      "MEMO-ENTRY" \
      "$index" \
      "$(extract_memo_manifest_field "$line" "timestamp")" \
      "$(extract_memo_manifest_field "$line" "batches")" \
      "$(extract_memo_manifest_field "$line" "filter")" \
      "$output_path" \
      "$(extract_memo_manifest_field "$line" "bytes")" \
      "$output_state"
  done < <(grep -ve '^$' "$manifest_path")

  if [ "$show_output" = "1" ]; then
    line="$(grep -ve '^$' "$manifest_path" | tail -n 1)"
    output_path="$(extract_memo_manifest_field "$line" "output")"
    print_memo_manifest_show "$output_path" "latest"
  fi
}

print_memo_manifest_show() {
  local output_path="$1"
  local source_label="$2"
  local output_state="missing"
  local line_count="0"
  local byte_count="0"
  local line

  if [ -f "$output_path" ]; then
    output_state="present"
    line_count="$(awk 'END { print NR }' "$output_path")"
    byte_count="$(wc -c < "$output_path" | tr -d '[:space:]')"
  fi

  printf '%s | source=%s | path=%s | state=%s' \
    "MEMO-SHOW" \
    "$source_label" \
    "$output_path" \
    "$output_state"
  if [ "$output_state" = "present" ]; then
    printf ' | lines=%s | bytes=%s\n' "$line_count" "$byte_count"
  else
    printf '\n'
  fi

  if [ "$output_state" != "present" ]; then
    return 0
  fi

  while IFS= read -r line; do
    printf '%s | %s\n' "MEMO-CONTENT" "$line"
  done < "$output_path"
}

collect_note_artifact_stats() {
  local batch="$1"
  local line filter name output_path output_state timestamp bytes key
  local -A key_seen=()
  local -A note_filter_map=()
  local -A note_name_map=()
  local -A note_output_path_map=()
  local -A note_output_state_map=()
  local -A note_timestamp_map=()
  local -A note_bytes_map=()
  local -a note_keys=()

  NOTE_ARTIFACT_COUNT=0
  NOTE_ARTIFACT_TRACKED_COUNT=0
  NOTE_ARTIFACT_UNTRACKED_COUNT=0
  NOTE_ARTIFACT_PRESENT_COUNT=0
  NOTE_ARTIFACT_LATEST_PATH=""
  NOTE_ARTIFACT_LATEST_NAME=""
  NOTE_ARTIFACT_LATEST_FILTER=""
  NOTE_ARTIFACT_LATEST_TIMESTAMP=""
  NOTE_ARTIFACT_LATEST_STATE="missing"
  NOTE_ARTIFACT_ROWS=()

  [ -f "$NOTE_MANIFEST_PATH" ] || return 0

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    manifest_line_matches_batch "$line" "$batch" || continue
    filter="$(extract_memo_manifest_field "$line" "filter")"
    name="$(extract_memo_manifest_field "$line" "name")"
    output_path="$(extract_memo_manifest_field "$line" "output")"
    timestamp="$(extract_memo_manifest_field "$line" "timestamp")"
    bytes="$(extract_memo_manifest_field "$line" "bytes")"
    output_state="missing"
    if [ -f "$output_path" ]; then
      output_state="present"
    fi
    key="${filter}:${name}"
    if [ -z "${key_seen[$key]:-}" ]; then
      key_seen["$key"]=1
      note_keys+=("$key")
    fi
    note_filter_map["$key"]="$filter"
    note_name_map["$key"]="$name"
    note_output_path_map["$key"]="$output_path"
    note_output_state_map["$key"]="$output_state"
    note_timestamp_map["$key"]="$timestamp"
    note_bytes_map["$key"]="$bytes"
    NOTE_ARTIFACT_LATEST_PATH="$output_path"
    NOTE_ARTIFACT_LATEST_NAME="$name"
    NOTE_ARTIFACT_LATEST_FILTER="$filter"
    NOTE_ARTIFACT_LATEST_TIMESTAMP="$timestamp"
    NOTE_ARTIFACT_LATEST_STATE="$output_state"
  done < <(grep -ve '^$' "$NOTE_MANIFEST_PATH")

  for key in "${note_keys[@]}"; do
    filter="${note_filter_map[$key]}"
    name="${note_name_map[$key]}"
    output_path="${note_output_path_map[$key]}"
    output_state="${note_output_state_map[$key]}"
    timestamp="${note_timestamp_map[$key]}"
    bytes="${note_bytes_map[$key]}"
    NOTE_ARTIFACT_COUNT=$((NOTE_ARTIFACT_COUNT + 1))
    if [ "$output_state" = "present" ]; then
      NOTE_ARTIFACT_PRESENT_COUNT=$((NOTE_ARTIFACT_PRESENT_COUNT + 1))
    fi
    case "$filter" in
      tracked-modified) NOTE_ARTIFACT_TRACKED_COUNT=$((NOTE_ARTIFACT_TRACKED_COUNT + 1)) ;;
      untracked) NOTE_ARTIFACT_UNTRACKED_COUNT=$((NOTE_ARTIFACT_UNTRACKED_COUNT + 1)) ;;
    esac
    NOTE_ARTIFACT_ROWS+=("$batch|$filter|$name|$output_path|$bytes|$output_state|$timestamp")
  done
}

collect_memo_artifact_stats() {
  local batch="$1"
  local line filter output_path output_state timestamp bytes key
  local -A key_seen=()
  local -A memo_output_path_map=()
  local -A memo_output_state_map=()
  local -A memo_timestamp_map=()
  local -A memo_bytes_map=()
  local -a memo_keys=()

  MEMO_ARTIFACT_COUNT=0
  MEMO_ARTIFACT_TRACKED_COUNT=0
  MEMO_ARTIFACT_UNTRACKED_COUNT=0
  MEMO_ARTIFACT_PRESENT_COUNT=0
  MEMO_ARTIFACT_LATEST_PATH=""
  MEMO_ARTIFACT_LATEST_FILTER=""
  MEMO_ARTIFACT_LATEST_TIMESTAMP=""
  MEMO_ARTIFACT_LATEST_STATE="missing"
  MEMO_ARTIFACT_ROWS=()

  [ -f "$MEMO_MANIFEST_PATH" ] || return 0

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    manifest_line_matches_batch "$line" "$batch" || continue
    filter="$(extract_memo_manifest_field "$line" "filter")"
    output_path="$(extract_memo_manifest_field "$line" "output")"
    timestamp="$(extract_memo_manifest_field "$line" "timestamp")"
    bytes="$(extract_memo_manifest_field "$line" "bytes")"
    output_state="missing"
    if [ -f "$output_path" ]; then
      output_state="present"
    fi
    key="$filter"
    if [ -z "${key_seen[$key]:-}" ]; then
      key_seen["$key"]=1
      memo_keys+=("$key")
    fi
    memo_output_path_map["$key"]="$output_path"
    memo_output_state_map["$key"]="$output_state"
    memo_timestamp_map["$key"]="$timestamp"
    memo_bytes_map["$key"]="$bytes"
    MEMO_ARTIFACT_LATEST_PATH="$output_path"
    MEMO_ARTIFACT_LATEST_FILTER="$filter"
    MEMO_ARTIFACT_LATEST_TIMESTAMP="$timestamp"
    MEMO_ARTIFACT_LATEST_STATE="$output_state"
  done < <(grep -ve '^$' "$MEMO_MANIFEST_PATH")

  for key in "${memo_keys[@]}"; do
    filter="$key"
    output_path="${memo_output_path_map[$key]}"
    output_state="${memo_output_state_map[$key]}"
    timestamp="${memo_timestamp_map[$key]}"
    bytes="${memo_bytes_map[$key]}"
    MEMO_ARTIFACT_COUNT=$((MEMO_ARTIFACT_COUNT + 1))
    if [ "$output_state" = "present" ]; then
      MEMO_ARTIFACT_PRESENT_COUNT=$((MEMO_ARTIFACT_PRESENT_COUNT + 1))
    fi
    case "$filter" in
      tracked-modified) MEMO_ARTIFACT_TRACKED_COUNT=$((MEMO_ARTIFACT_TRACKED_COUNT + 1)) ;;
      untracked) MEMO_ARTIFACT_UNTRACKED_COUNT=$((MEMO_ARTIFACT_UNTRACKED_COUNT + 1)) ;;
    esac
    MEMO_ARTIFACT_ROWS+=("$batch|$filter|$output_path|$bytes|$output_state|$timestamp")
  done
}

count_matched_outside_batch_groups() {
  local name focus files_csv file
  local -a group_files=()
  local matched_count=0
  local has_match="0"

  collect_outside_batch_changes

  while IFS='|' read -r name focus files_csv; do
    [ -n "$name" ] || continue
    has_match="0"
    IFS=';' read -r -a group_files <<< "$files_csv"
    for file in "${group_files[@]}"; do
      [ -n "$file" ] || continue
      if printf '%s\n' "${OUTSIDE_BATCH_TRACKED_MODIFIED_FILES[@]}" | grep -Fxq "$file" || \
         printf '%s\n' "${OUTSIDE_BATCH_UNTRACKED_FILES[@]}" | grep -Fxq "$file"; then
        has_match="1"
        break
      fi
    done
    if [ "$has_match" = "1" ]; then
      matched_count=$((matched_count + 1))
    fi
  done < <(resolve_outside_batch_groups)

  printf '%s\n' "$matched_count"
}

count_selected_outside_landing_batches() {
  local selected_name_raw="${1:-}"
  local selected_name=""
  local name focus files_csv file
  local -a group_files=()
  local matched_count=0
  local has_match="0"

  collect_outside_batch_changes
  selected_name="$(normalize_outside_landing_batch_selection "$selected_name_raw")"

  while IFS='|' read -r name focus files_csv; do
    [ -n "$name" ] || continue
    if [ -n "$selected_name" ] && [ "$name" != "$selected_name" ]; then
      continue
    fi
    has_match="0"
    IFS=';' read -r -a group_files <<< "$files_csv"
    for file in "${group_files[@]}"; do
      [ -n "$file" ] || continue
      if printf '%s\n' "${OUTSIDE_BATCH_TRACKED_MODIFIED_FILES[@]}" | grep -Fxq "$file" || \
         printf '%s\n' "${OUTSIDE_BATCH_UNTRACKED_FILES[@]}" | grep -Fxq "$file"; then
        has_match="1"
        break
      fi
    done
    if [ "$has_match" = "1" ]; then
      matched_count=$((matched_count + 1))
    fi
  done < <(resolve_outside_batch_groups)

  printf '%s\n' "$matched_count"
}

emit_curated_tracked_subchange_names_for_batch() {
  local batch="$1"

  case "$batch" in
    batch-2)
      printf '%s\n' \
        'bounded-wait-guards' \
        'stack-reset-recreate' \
        'isolated-dns-precheck-hardening' \
        'post-fix-verification-retry'
      ;;
  esac
}

count_curated_tracked_subchanges_for_batch() {
  local batch="$1"
  local count="0"
  local name

  while IFS= read -r name; do
    [ -n "$name" ] || continue
    count=$((count + 1))
  done < <(emit_curated_tracked_subchange_names_for_batch "$batch")

  printf '%s\n' "$count"
}

count_curated_untracked_groups_for_batch() {
  local batch="$1"
  local count="0"
  local name focus files_csv

  while IFS='|' read -r name focus files_csv; do
    [ -n "$name" ] || continue
    count=$((count + 1))
  done < <(emit_untracked_group_definitions_for_batch "$batch")

  printf '%s\n' "$count"
}

resolve_batch_artifact_index_state() {
  local note_count="$1"
  local expected_notes="$2"
  local present_notes="$3"
  local memo_count="$4"
  local expected_memos="$5"
  local present_memos="$6"

  if [ "$note_count" -eq 0 ] && [ "$memo_count" -eq 0 ]; then
    printf '%s\n' "none"
    return 0
  fi

  if [ "$note_count" -lt "$expected_notes" ] || [ "$memo_count" -lt "$expected_memos" ] || [ "$present_notes" -lt "$expected_notes" ] || [ "$present_memos" -lt "$expected_memos" ]; then
    printf '%s\n' "partial"
    return 0
  fi

  printf '%s\n' "complete"
}

print_batch_handoff_index() {
  local batch="$1"
  local show_rows="${2:-0}"
  local tracked_expected_notes="0"
  local untracked_expected_notes="0"
  local expected_notes="0"
  local expected_memos="0"
  local artifact_state="none"
  local row remainder filter name output_path bytes output_state timestamp

  collect_note_artifact_stats "$batch"
  collect_memo_artifact_stats "$batch"
  tracked_expected_notes="$(count_curated_tracked_subchanges_for_batch "$batch")"
  untracked_expected_notes="$(count_curated_untracked_groups_for_batch "$batch")"
  expected_notes=$((tracked_expected_notes + untracked_expected_notes))
  expected_memos=0
  if [ "$tracked_expected_notes" -gt 0 ]; then
    expected_memos=$((expected_memos + 1))
  fi
  if [ "$untracked_expected_notes" -gt 0 ]; then
    expected_memos=$((expected_memos + 1))
  fi
  artifact_state="$(resolve_batch_artifact_index_state "$NOTE_ARTIFACT_COUNT" "$expected_notes" "$NOTE_ARTIFACT_PRESENT_COUNT" "$MEMO_ARTIFACT_COUNT" "$expected_memos" "$MEMO_ARTIFACT_PRESENT_COUNT")"

  printf '%s | HANDOFF-ARTIFACTS | artifact-state=%s | notes=%s/%s | tracked-notes=%s/%s | untracked-notes=%s/%s | present-notes=%s | memos=%s/%s | tracked-memos=%s | untracked-memos=%s | present-memos=%s | latest-note=%s | latest-memo=%s\n' \
    "$batch" \
    "$artifact_state" \
    "$NOTE_ARTIFACT_COUNT" \
    "$expected_notes" \
    "$NOTE_ARTIFACT_TRACKED_COUNT" \
    "$tracked_expected_notes" \
    "$NOTE_ARTIFACT_UNTRACKED_COUNT" \
    "$untracked_expected_notes" \
    "$NOTE_ARTIFACT_PRESENT_COUNT" \
    "$MEMO_ARTIFACT_COUNT" \
    "$expected_memos" \
    "$MEMO_ARTIFACT_TRACKED_COUNT" \
    "$MEMO_ARTIFACT_UNTRACKED_COUNT" \
    "$MEMO_ARTIFACT_PRESENT_COUNT" \
    "${NOTE_ARTIFACT_LATEST_PATH:-"(none)"}" \
    "${MEMO_ARTIFACT_LATEST_PATH:-"(none)"}"

  if [ "$show_rows" != "1" ]; then
    return 0
  fi

  for row in "${NOTE_ARTIFACT_ROWS[@]}"; do
    remainder="${row#*|}"
    filter="${remainder%%|*}"
    remainder="${remainder#*|}"
    name="${remainder%%|*}"
    remainder="${remainder#*|}"
    output_path="${remainder%%|*}"
    remainder="${remainder#*|}"
    bytes="${remainder%%|*}"
    remainder="${remainder#*|}"
    output_state="${remainder%%|*}"
    timestamp="${remainder#*|}"
    printf '%s | NOTE-ARTIFACT | filter=%s | name=%s | output=%s | bytes=%s | output-state=%s | timestamp=%s\n' \
      "$batch" \
      "$filter" \
      "$name" \
      "$output_path" \
      "$bytes" \
      "$output_state" \
      "$timestamp"
  done

  for row in "${MEMO_ARTIFACT_ROWS[@]}"; do
    remainder="${row#*|}"
    filter="${remainder%%|*}"
    remainder="${remainder#*|}"
    output_path="${remainder%%|*}"
    remainder="${remainder#*|}"
    bytes="${remainder%%|*}"
    remainder="${remainder#*|}"
    output_state="${remainder%%|*}"
    timestamp="${remainder#*|}"
    printf '%s | MEMO-ARTIFACT | filter=%s | output=%s | bytes=%s | output-state=%s | timestamp=%s\n' \
      "$batch" \
      "$filter" \
      "$output_path" \
      "$bytes" \
      "$output_state" \
      "$timestamp"
  done
}

print_outside_batch_handoff_index() {
  local show_rows="${1:-0}"
  local outside_expected_notes="0"
  local outside_expected_memos="0"
  local artifact_state="none"
  local row remainder filter name output_path bytes output_state timestamp

  collect_outside_batch_changes
  collect_note_artifact_stats "outside-batches"
  collect_memo_artifact_stats "outside-batches"

  outside_expected_notes="$(count_matched_outside_batch_groups)"
  if [ "$outside_expected_notes" -gt 0 ]; then
    outside_expected_memos=1
  fi

  artifact_state="$(resolve_batch_artifact_index_state "$NOTE_ARTIFACT_COUNT" "$outside_expected_notes" "$NOTE_ARTIFACT_PRESENT_COUNT" "$MEMO_ARTIFACT_COUNT" "$outside_expected_memos" "$MEMO_ARTIFACT_PRESENT_COUNT")"

  printf '%s | HANDOFF-ARTIFACTS | artifact-state=%s | notes=%s/%s | outside-notes=%s/%s | present-notes=%s | memos=%s/%s | outside-memos=%s | present-memos=%s | latest-note=%s | latest-memo=%s\n' \
    "outside-batches" \
    "$artifact_state" \
    "$NOTE_ARTIFACT_COUNT" \
    "$outside_expected_notes" \
    "$NOTE_ARTIFACT_COUNT" \
    "$outside_expected_notes" \
    "$NOTE_ARTIFACT_PRESENT_COUNT" \
    "$MEMO_ARTIFACT_COUNT" \
    "$outside_expected_memos" \
    "$MEMO_ARTIFACT_COUNT" \
    "$MEMO_ARTIFACT_PRESENT_COUNT" \
    "${NOTE_ARTIFACT_LATEST_PATH:-"(none)"}" \
    "${MEMO_ARTIFACT_LATEST_PATH:-"(none)"}"

  if [ "$show_rows" != "1" ]; then
    return 0
  fi

  for row in "${NOTE_ARTIFACT_ROWS[@]}"; do
    remainder="${row#*|}"
    filter="${remainder%%|*}"
    remainder="${remainder#*|}"
    name="${remainder%%|*}"
    remainder="${remainder#*|}"
    output_path="${remainder%%|*}"
    remainder="${remainder#*|}"
    bytes="${remainder%%|*}"
    remainder="${remainder#*|}"
    output_state="${remainder%%|*}"
    timestamp="${remainder#*|}"
    printf '%s | NOTE-ARTIFACT | filter=%s | name=%s | output=%s | bytes=%s | state=%s | timestamp=%s\n' \
      "outside-batches" \
      "$filter" \
      "$name" \
      "$output_path" \
      "$bytes" \
      "$output_state" \
      "$timestamp"
  done

  for row in "${MEMO_ARTIFACT_ROWS[@]}"; do
    remainder="${row#*|}"
    filter="${remainder%%|*}"
    remainder="${remainder#*|}"
    output_path="${remainder%%|*}"
    remainder="${remainder#*|}"
    bytes="${remainder%%|*}"
    remainder="${remainder#*|}"
    output_state="${remainder%%|*}"
    timestamp="${remainder#*|}"
    printf '%s | MEMO-ARTIFACT | filter=%s | output=%s | bytes=%s | state=%s | timestamp=%s\n' \
      "outside-batches" \
      "$filter" \
      "$output_path" \
      "$bytes" \
      "$output_state" \
      "$timestamp"
  done
}

print_handoff_index() {
  local show_rows="${1:-0}"
  shift || true
  local batches=("$@")
  local batch
  local outside_target_present="0"
  local total_notes=0
  local total_expected_notes=0
  local total_memos=0
  local total_expected_memos=0
  local total_present_notes=0
  local total_present_memos=0
  local handoff_complete=0
  local handoff_partial=0
  local handoff_none=0
  local tracked_expected_notes="0"
  local untracked_expected_notes="0"
  local expected_notes="0"
  local expected_memos="0"
  local artifact_state="none"

  if [ "${#batches[@]}" -eq 0 ]; then
    batches=(batch-1 batch-2 batch-3 batch-4 batch-5)
  fi

  collect_outside_batch_changes
  if [ "$OUTSIDE_BATCH_TOTAL" -gt 0 ]; then
    outside_target_present="1"
  fi

  printf '%s | note-manifest=%s | memo-manifest=%s | batches=%s | outside-batches=%s\n' \
    "HANDOFF-INDEX" \
    "$NOTE_MANIFEST_PATH" \
    "$MEMO_MANIFEST_PATH" \
    "${#batches[@]}" \
    "$outside_target_present"

  for batch in "${batches[@]}"; do
    print_batch_handoff_index "$batch" "$show_rows"
    tracked_expected_notes="$(count_curated_tracked_subchanges_for_batch "$batch")"
    untracked_expected_notes="$(count_curated_untracked_groups_for_batch "$batch")"
    expected_notes=$((tracked_expected_notes + untracked_expected_notes))
    expected_memos=0
    if [ "$tracked_expected_notes" -gt 0 ]; then
      expected_memos=$((expected_memos + 1))
    fi
    if [ "$untracked_expected_notes" -gt 0 ]; then
      expected_memos=$((expected_memos + 1))
    fi
    artifact_state="$(resolve_batch_artifact_index_state "$NOTE_ARTIFACT_COUNT" "$expected_notes" "$NOTE_ARTIFACT_PRESENT_COUNT" "$MEMO_ARTIFACT_COUNT" "$expected_memos" "$MEMO_ARTIFACT_PRESENT_COUNT")"
    total_notes=$((total_notes + NOTE_ARTIFACT_COUNT))
    total_expected_notes=$((total_expected_notes + expected_notes))
    total_memos=$((total_memos + MEMO_ARTIFACT_COUNT))
    total_expected_memos=$((total_expected_memos + expected_memos))
    total_present_notes=$((total_present_notes + NOTE_ARTIFACT_PRESENT_COUNT))
    total_present_memos=$((total_present_memos + MEMO_ARTIFACT_PRESENT_COUNT))
    case "$artifact_state" in
      complete) handoff_complete=$((handoff_complete + 1)) ;;
      partial) handoff_partial=$((handoff_partial + 1)) ;;
      none) handoff_none=$((handoff_none + 1)) ;;
    esac
  done

  if [ "$outside_target_present" = "1" ]; then
    print_outside_batch_handoff_index "$show_rows"
    total_notes=$((total_notes + NOTE_ARTIFACT_COUNT))
    total_expected_notes=$((total_expected_notes + $(count_matched_outside_batch_groups)))
    total_memos=$((total_memos + MEMO_ARTIFACT_COUNT))
    total_present_notes=$((total_present_notes + NOTE_ARTIFACT_PRESENT_COUNT))
    total_present_memos=$((total_present_memos + MEMO_ARTIFACT_PRESENT_COUNT))
    if [ "$(count_matched_outside_batch_groups)" -gt 0 ]; then
      total_expected_memos=$((total_expected_memos + 1))
    fi
    artifact_state="$(resolve_batch_artifact_index_state "$NOTE_ARTIFACT_COUNT" "$(count_matched_outside_batch_groups)" "$NOTE_ARTIFACT_PRESENT_COUNT" "$MEMO_ARTIFACT_COUNT" "$([ "$(count_matched_outside_batch_groups)" -gt 0 ] && printf '1' || printf '0')" "$MEMO_ARTIFACT_PRESENT_COUNT")"
    case "$artifact_state" in
      complete) handoff_complete=$((handoff_complete + 1)) ;;
      partial) handoff_partial=$((handoff_partial + 1)) ;;
      none) handoff_none=$((handoff_none + 1)) ;;
    esac
  fi

  printf '%s | notes=%s/%s | present-notes=%s | memos=%s/%s | present-memos=%s | complete=%s | partial=%s | none=%s | outside-batches=%s\n' \
    "HANDOFF-INDEX-SUMMARY" \
    "$total_notes" \
    "$total_expected_notes" \
    "$total_present_notes" \
    "$total_memos" \
    "$total_expected_memos" \
    "$total_present_memos" \
    "$handoff_complete" \
    "$handoff_partial" \
    "$handoff_none" \
    "$outside_target_present"
}

resolve_batch_landing_state() {
  local readiness="$1"
  local handoff_state="$2"

  if [ "$readiness" = "blocked" ]; then
    printf '%s\n' "blocked"
    return 0
  fi

  if [ "$handoff_state" = "complete" ]; then
    printf '%s\n' "ready-for-landing"
    return 0
  fi

  printf '%s\n' "pending-handoff"
}

print_batch_landing_plan() {
  local batch="$1"
  local show_rows="${2:-0}"
  local readiness reason tracked_expected_notes untracked_expected_notes expected_notes expected_memos artifact_state landing_state order commit_scope file

  compute_batch_status "$batch"
  readiness="$(resolve_batch_readiness "$BATCH_STATUS_MISSING" "$BATCH_STATUS_TRACKED_MODIFIED" "$BATCH_STATUS_UNTRACKED")"
  reason="$(resolve_batch_reason "$BATCH_STATUS_MISSING" "$BATCH_STATUS_TRACKED_MODIFIED" "$BATCH_STATUS_UNTRACKED")"
  resolve_batch_handoff_fields "$batch" "$readiness" "$reason"
  collect_note_artifact_stats "$batch"
  collect_memo_artifact_stats "$batch"
  tracked_expected_notes="$(count_curated_tracked_subchanges_for_batch "$batch")"
  untracked_expected_notes="$(count_curated_untracked_groups_for_batch "$batch")"
  expected_notes=$((tracked_expected_notes + untracked_expected_notes))
  expected_memos=0
  if [ "$tracked_expected_notes" -gt 0 ]; then
    expected_memos=$((expected_memos + 1))
  fi
  if [ "$untracked_expected_notes" -gt 0 ]; then
    expected_memos=$((expected_memos + 1))
  fi
  artifact_state="$(resolve_batch_artifact_index_state "$NOTE_ARTIFACT_COUNT" "$expected_notes" "$NOTE_ARTIFACT_PRESENT_COUNT" "$MEMO_ARTIFACT_COUNT" "$expected_memos" "$MEMO_ARTIFACT_PRESENT_COUNT")"
  landing_state="$(resolve_batch_landing_state "$readiness" "$BATCH_HANDOFF_STATE")"
  order="$(resolve_batch_order "$batch")"
  commit_scope="$(resolve_batch_commit_scope "$batch")"

  printf '%s | LANDING-STEP | order=%s | landing-state=%s | readiness=%s | handoff=%s | artifact-state=%s | commit-scope=%s | files=%s | tracked-modified=%s | untracked=%s | missing=%s\n' \
    "$batch" \
    "$order" \
    "$landing_state" \
    "$readiness" \
    "$BATCH_HANDOFF_STATE" \
    "$artifact_state" \
    "$commit_scope" \
    "$BATCH_STATUS_TOTAL" \
    "$BATCH_STATUS_TRACKED_MODIFIED" \
    "$BATCH_STATUS_UNTRACKED" \
    "$BATCH_STATUS_MISSING"

  if [ "$show_rows" != "1" ]; then
    return 0
  fi

  printf '%s | LANDING-HANDOFF | next=%s\n' "$batch" "$BATCH_HANDOFF_NEXT"
  for file in "${BATCH_STATUS_TRACKED_MODIFIED_FILES[@]}"; do
    printf '%s | LANDING-FILE | tracked-modified | %s\n' "$batch" "$file"
  done
  for file in "${BATCH_STATUS_UNTRACKED_FILES[@]}"; do
    printf '%s | LANDING-FILE | untracked | %s\n' "$batch" "$file"
  done
  for file in "${BATCH_STATUS_MISSING_FILES[@]}"; do
    printf '%s | LANDING-FILE | missing | %s\n' "$batch" "$file"
  done
  if [ -n "${NOTE_ARTIFACT_LATEST_PATH:-}" ]; then
    printf '%s | LANDING-ARTIFACT | type=latest-note | path=%s\n' "$batch" "$NOTE_ARTIFACT_LATEST_PATH"
  fi
  if [ -n "${MEMO_ARTIFACT_LATEST_PATH:-}" ]; then
    printf '%s | LANDING-ARTIFACT | type=latest-memo | path=%s\n' "$batch" "$MEMO_ARTIFACT_LATEST_PATH"
  fi
}

print_landing_plan() {
  local show_rows="${1:-0}"
  shift || true
  local batches=("$@")
  local batch landing_state readiness reason ready_for_landing=0 pending_handoff=0 blocked=0

  if [ "${#batches[@]}" -eq 0 ]; then
    batches=(batch-1 batch-2 batch-3 batch-4 batch-5)
  fi

  printf '%s | batches=%s\n' "LANDING-PLAN" "${#batches[@]}"

  for batch in "${batches[@]}"; do
    print_batch_landing_plan "$batch" "$show_rows"
    compute_batch_status "$batch"
    readiness="$(resolve_batch_readiness "$BATCH_STATUS_MISSING" "$BATCH_STATUS_TRACKED_MODIFIED" "$BATCH_STATUS_UNTRACKED")"
    reason="$(resolve_batch_reason "$BATCH_STATUS_MISSING" "$BATCH_STATUS_TRACKED_MODIFIED" "$BATCH_STATUS_UNTRACKED")"
    resolve_batch_handoff_fields "$batch" "$readiness" "$reason"
    landing_state="$(resolve_batch_landing_state "$readiness" "$BATCH_HANDOFF_STATE")"
    case "$landing_state" in
      ready-for-landing) ready_for_landing=$((ready_for_landing + 1)) ;;
      pending-handoff) pending_handoff=$((pending_handoff + 1)) ;;
      blocked) blocked=$((blocked + 1)) ;;
    esac
  done

  printf '%s | ready-for-landing=%s | pending-handoff=%s | blocked=%s\n' \
    "LANDING-PLAN-SUMMARY" \
    "$ready_for_landing" \
    "$pending_handoff" \
    "$blocked"
}

emit_default_landing_command_targets() {
  local name focus files_csv file
  local -a group_files=()
  local matched="0"

  printf '%s\n' batch-1 batch-2 batch-3 batch-4 batch-5

  collect_outside_batch_changes
  while IFS='|' read -r name focus files_csv; do
    [ -n "$name" ] || continue
    matched="0"
    IFS=';' read -r -a group_files <<< "$files_csv"
    for file in "${group_files[@]}"; do
      [ -n "$file" ] || continue
      if printf '%s\n' "${OUTSIDE_BATCH_TRACKED_MODIFIED_FILES[@]}" | grep -Fxq "$file" || \
         printf '%s\n' "${OUTSIDE_BATCH_UNTRACKED_FILES[@]}" | grep -Fxq "$file"; then
        matched="1"
        break
      fi
    done
    if [ "$matched" = "1" ]; then
      resolve_outside_landing_batch_name "$name"
    fi
  done < <(resolve_outside_batch_groups)
}

print_batch_landing_commands() {
  local batch="$1"
  local readiness="" reason="" landing_state="" commit_scope="" commit_title="" pr_title="" next_command=""
  local command_state="" stage_command="" commit_command="" file_count=0
  local -a staged_files=()

  compute_batch_status "$batch"
  readiness="$(resolve_batch_readiness "$BATCH_STATUS_MISSING" "$BATCH_STATUS_TRACKED_MODIFIED" "$BATCH_STATUS_UNTRACKED")"
  reason="$(resolve_batch_reason "$BATCH_STATUS_MISSING" "$BATCH_STATUS_TRACKED_MODIFIED" "$BATCH_STATUS_UNTRACKED")"
  resolve_batch_handoff_fields "$batch" "$readiness" "$reason"
  landing_state="$(resolve_batch_landing_state "$readiness" "$BATCH_HANDOFF_STATE")"
  commit_scope="$(resolve_batch_commit_scope "$batch")"
  commit_title="$(resolve_batch_commit_title "$batch")"
  pr_title="$(resolve_batch_pr_title "$batch")"
  next_command="$BATCH_HANDOFF_NEXT"
  staged_files=("${BATCH_STATUS_TRACKED_MODIFIED_FILES[@]}" "${BATCH_STATUS_UNTRACKED_FILES[@]}")
  file_count="${#staged_files[@]}"

  if [ "$landing_state" = "blocked" ]; then
    command_state="blocked"
  elif [ "$landing_state" != "ready-for-landing" ]; then
    command_state="pending-handoff"
  elif [ "$file_count" -eq 0 ]; then
    command_state="noop"
  else
    command_state="actionable"
  fi

  printf '%s | LANDING-COMMAND-STEP | state=%s | landing-state=%s | commit-scope=%s | files=%s | tracked-modified=%s | untracked=%s | missing=%s\n' \
    "$batch" \
    "$command_state" \
    "$landing_state" \
    "$commit_scope" \
    "$file_count" \
    "$BATCH_STATUS_TRACKED_MODIFIED" \
    "$BATCH_STATUS_UNTRACKED" \
    "$BATCH_STATUS_MISSING"

  if [ "$command_state" = "actionable" ]; then
    stage_command="$(build_git_add_command "${staged_files[@]}")"
    commit_command="$(build_git_commit_command "$commit_title")"
    printf '%s | LANDING-COMMAND | type=stage | command=%s\n' "$batch" "$stage_command"
    printf '%s | LANDING-COMMAND | type=commit | command=%s\n' "$batch" "$commit_command"
    printf '%s | LANDING-COMMAND | type=commit-title | value=%s\n' "$batch" "$commit_title"
    printf '%s | LANDING-COMMAND | type=pr-title | value=%s\n' "$batch" "$pr_title"
  elif [ "$command_state" = "noop" ]; then
    printf '%s | LANDING-COMMAND | type=stage | command=echo no-files-to-stage\n' "$batch"
    printf '%s | LANDING-COMMAND | type=commit-title | value=%s\n' "$batch" "$commit_title"
    printf '%s | LANDING-COMMAND | type=pr-title | value=%s\n' "$batch" "$pr_title"
  else
    printf '%s | LANDING-COMMAND | type=next | command=%s\n' "$batch" "$next_command"
  fi
}

print_outside_landing_batch_commands() {
  local selected_name_raw="$1"
  local selected_name=""
  local commit_title="" pr_title="" artifact_state="" landing_state="" next_command=""
  local command_state="" stage_command="" commit_command="" file_count=0
  local -a staged_files=()

  selected_name="$(normalize_outside_landing_batch_selection "$selected_name_raw")"
  collect_outside_landing_batch_state "$selected_name"
  if [ "$OUTSIDE_LANDING_BATCH_FOUND" != "1" ]; then
    echo "Unknown outside landing batch: ${selected_name_raw}" >&2
    return 1
  fi

  artifact_state="$(resolve_outside_landing_batch_artifact_state "$selected_name")"
  landing_state="$(resolve_outside_landing_batch_state "$artifact_state")"
  next_command="$(resolve_outside_landing_batch_next_command "$selected_name")"
  commit_title="$(outside_landing_commit_title "$OUTSIDE_LANDING_BATCH_NAME")"
  pr_title="$(outside_landing_pr_title "$OUTSIDE_LANDING_BATCH_NAME")"
  staged_files=("${OUTSIDE_LANDING_BATCH_TRACKED_FILES[@]}" "${OUTSIDE_LANDING_BATCH_UNTRACKED_FILES[@]}")
  file_count="${#staged_files[@]}"

  if [ "$landing_state" != "ready-for-landing" ]; then
    command_state="pending-handoff"
  elif [ "$file_count" -eq 0 ]; then
    command_state="noop"
  else
    command_state="actionable"
  fi

  printf '%s | LANDING-COMMAND-STEP | state=%s | landing-state=%s | commit-scope=%s | focus=%s | files=%s | tracked-modified=%s | untracked=%s | missing=0\n' \
    "$OUTSIDE_LANDING_BATCH_NAME" \
    "$command_state" \
    "$landing_state" \
    "$OUTSIDE_LANDING_BATCH_NAME" \
    "$OUTSIDE_LANDING_BATCH_FOCUS" \
    "$file_count" \
    "${#OUTSIDE_LANDING_BATCH_TRACKED_FILES[@]}" \
    "${#OUTSIDE_LANDING_BATCH_UNTRACKED_FILES[@]}"

  if [ "$command_state" = "actionable" ]; then
    stage_command="$(build_git_add_command "${staged_files[@]}")"
    commit_command="$(build_git_commit_command "$commit_title")"
    printf '%s | LANDING-COMMAND | type=stage | command=%s\n' "$OUTSIDE_LANDING_BATCH_NAME" "$stage_command"
    printf '%s | LANDING-COMMAND | type=commit | command=%s\n' "$OUTSIDE_LANDING_BATCH_NAME" "$commit_command"
    printf '%s | LANDING-COMMAND | type=commit-title | value=%s\n' "$OUTSIDE_LANDING_BATCH_NAME" "$commit_title"
    printf '%s | LANDING-COMMAND | type=pr-title | value=%s\n' "$OUTSIDE_LANDING_BATCH_NAME" "$pr_title"
  elif [ "$command_state" = "noop" ]; then
    printf '%s | LANDING-COMMAND | type=stage | command=echo no-files-to-stage\n' "$OUTSIDE_LANDING_BATCH_NAME"
    printf '%s | LANDING-COMMAND | type=commit-title | value=%s\n' "$OUTSIDE_LANDING_BATCH_NAME" "$commit_title"
    printf '%s | LANDING-COMMAND | type=pr-title | value=%s\n' "$OUTSIDE_LANDING_BATCH_NAME" "$pr_title"
  else
    printf '%s | LANDING-COMMAND | type=next | command=%s\n' "$OUTSIDE_LANDING_BATCH_NAME" "$next_command"
  fi
}

print_landing_commands() {
  local targets=("$@")
  local target="" actionable=0 noop=0 pending_handoff=0 blocked=0 total_steps=0
  local output=""

  if [ "${#targets[@]}" -eq 0 ]; then
    mapfile -t targets < <(emit_default_landing_command_targets)
  fi

  for target in "${targets[@]}"; do
    [ -n "$target" ] || continue
    if [[ "$target" == batch-* ]]; then
      output="$(print_batch_landing_commands "$target")"
    elif [[ "$target" == outside-* ]]; then
      output="$(print_outside_landing_batch_commands "$target")"
    else
      echo "Unknown landing command target: $target" >&2
      exit 1
    fi

    printf '%s\n' "$output"
    total_steps=$((total_steps + 1))
    case "$output" in
      *"LANDING-COMMAND-STEP | state=actionable"*) actionable=$((actionable + 1)) ;;
      *"LANDING-COMMAND-STEP | state=noop"*) noop=$((noop + 1)) ;;
      *"LANDING-COMMAND-STEP | state=blocked"*) blocked=$((blocked + 1)) ;;
      *) pending_handoff=$((pending_handoff + 1)) ;;
    esac
  done

  printf '%s | steps=%s | actionable=%s | noop=%s | pending-handoff=%s | blocked=%s\n' \
    "LANDING-COMMANDS" \
    "$total_steps" \
    "$actionable" \
    "$noop" \
    "$pending_handoff" \
    "$blocked"
}

resolve_git_file_state() {
  local file="$1"
  local porcelain

  if [ ! -e "$ROOT_DIR/$file" ]; then
    printf '%s\n' "missing"
    return 0
  fi

  porcelain="$(git -C "$ROOT_DIR" status --porcelain=v1 --untracked-files=all -- "$file" | head -n 1 || true)"
  if [ -z "$porcelain" ]; then
    printf '%s\n' "clean"
    return 0
  fi

  case "${porcelain:0:2}" in
    '??')
      printf '%s\n' "untracked"
      ;;
    *)
      printf '%s\n' "tracked-modified"
      ;;
  esac
}

resolve_batch_readiness() {
  local missing="$1"
  local tracked_modified="$2"
  local untracked="$3"

  if [ "$missing" -gt 0 ]; then
    printf '%s\n' "blocked"
  elif [ "$tracked_modified" -gt 0 ] || [ "$untracked" -gt 0 ]; then
    printf '%s\n' "needs-landing"
  else
    printf '%s\n' "ready"
  fi
}

resolve_batch_reason() {
  local missing="$1"
  local tracked_modified="$2"
  local untracked="$3"

  if [ "$missing" -gt 0 ]; then
    printf '%s\n' "missing-files-present"
  elif [ "$tracked_modified" -gt 0 ]; then
    printf '%s\n' "tracked-modified-present"
  elif [ "$untracked" -gt 0 ]; then
    printf '%s\n' "untracked-present"
  else
    printf '%s\n' "all-files-clean"
  fi
}

resolve_readiness_priority() {
  case "$1" in
    blocked) printf '%s\n' "0" ;;
    needs-landing) printf '%s\n' "1" ;;
    ready) printf '%s\n' "2" ;;
    *)
      echo "Unknown readiness state: $1" >&2
      exit 1
      ;;
  esac
}

resolve_reason_priority() {
  case "$1" in
    missing-files-present) printf '%s\n' "0" ;;
    tracked-modified-present) printf '%s\n' "1" ;;
    untracked-present) printf '%s\n' "2" ;;
    all-files-clean) printf '%s\n' "3" ;;
    *)
      echo "Unknown batch reason: $1" >&2
      exit 1
      ;;
  esac
}

resolve_first_action() {
  local batch="$1"
  local reason="$2"

  case "$reason" in
    missing-files-present)
      printf '%s\n' "./scripts/verify/run-review-batch-checks.sh --split ${batch} --filter missing"
      ;;
    tracked-modified-present)
      printf '%s\n' "./scripts/verify/run-review-batch-checks.sh --subchanges ${batch} --filter tracked-modified"
      ;;
    untracked-present)
      printf '%s\n' "./scripts/verify/run-review-batch-checks.sh --split ${batch} --filter untracked"
      ;;
    all-files-clean)
      printf '%s\n' "echo no-pending-review-actions"
      ;;
    *)
      echo "Unknown batch reason for first action: $reason" >&2
      exit 1
      ;;
  esac
}

print_git_changed_paths_with_state() {
  local entry="" status="" path="" renamed_path=""

  while IFS= read -r -d '' entry; do
    [ -n "$entry" ] || continue
    status="${entry:0:2}"
    path="${entry:3}"
    case "$status" in
      R*|*R|C*|*C)
        if IFS= read -r -d '' renamed_path; then
          path="$renamed_path"
        fi
        ;;
    esac
    if [ "$status" = "??" ]; then
      printf '%s\t%s\n' "untracked" "$path"
    else
      printf '%s\t%s\n' "tracked-modified" "$path"
    fi
  done < <(git -C "$ROOT_DIR" status --porcelain=v1 --untracked-files=all -z)
}

collect_outside_batch_changes() {
  local batch_manifest_file="" state="" file=""

  OUTSIDE_BATCH_TOTAL=0
  OUTSIDE_BATCH_TRACKED_MODIFIED=0
  OUTSIDE_BATCH_UNTRACKED=0
  OUTSIDE_BATCH_STATE_LINES=()
  OUTSIDE_BATCH_TRACKED_MODIFIED_FILES=()
  OUTSIDE_BATCH_UNTRACKED_FILES=()

  batch_manifest_file="$(mktemp)"
  {
    resolve_batch_files batch-1
    resolve_batch_files batch-2
    resolve_batch_files batch-3
    resolve_batch_files batch-4
    resolve_batch_files batch-5
  } | sort -u > "$batch_manifest_file"

  while IFS=$'\t' read -r state file; do
    [ -n "$file" ] || continue
    if grep -Fxq "$file" "$batch_manifest_file"; then
      continue
    fi
    OUTSIDE_BATCH_TOTAL=$((OUTSIDE_BATCH_TOTAL + 1))
    OUTSIDE_BATCH_STATE_LINES+=("OUTSIDE-BATCH | $state | $file")
    case "$state" in
      tracked-modified)
        OUTSIDE_BATCH_TRACKED_MODIFIED=$((OUTSIDE_BATCH_TRACKED_MODIFIED + 1))
        OUTSIDE_BATCH_TRACKED_MODIFIED_FILES+=("$file")
        ;;
      untracked)
        OUTSIDE_BATCH_UNTRACKED=$((OUTSIDE_BATCH_UNTRACKED + 1))
        OUTSIDE_BATCH_UNTRACKED_FILES+=("$file")
        ;;
      *)
        echo "Unknown outside-batch git state for $file: $state" >&2
        rm -f "$batch_manifest_file"
        exit 1
        ;;
    esac
  done < <(print_git_changed_paths_with_state | sort -t $'\t' -k2,2)

  rm -f "$batch_manifest_file"
}

resolve_outside_batch_readiness() {
  local total="$1"

  if [ "$total" -gt 0 ]; then
    printf '%s\n' "needs-batching"
  else
    printf '%s\n' "ready"
  fi
}

resolve_outside_batch_reason() {
  local total="$1"

  if [ "$total" -gt 0 ]; then
    printf '%s\n' "outside-batch-changes-present"
  else
    printf '%s\n' "no-outside-batch-changes"
  fi
}

resolve_overall_review_readiness() {
  local missing="$1"
  local tracked_modified="$2"
  local untracked="$3"
  local outside_total="$4"

  if [ "$missing" -gt 0 ]; then
    printf '%s\n' "blocked"
  elif [ "$tracked_modified" -gt 0 ] || [ "$untracked" -gt 0 ]; then
    printf '%s\n' "needs-landing"
  elif [ "$outside_total" -gt 0 ]; then
    printf '%s\n' "needs-batching"
  else
    printf '%s\n' "ready"
  fi
}

resolve_overall_review_reason() {
  local missing="$1"
  local tracked_modified="$2"
  local untracked="$3"
  local outside_total="$4"

  if [ "$missing" -gt 0 ]; then
    printf '%s\n' "missing-files-present"
  elif [ "$tracked_modified" -gt 0 ]; then
    printf '%s\n' "tracked-modified-present"
  elif [ "$untracked" -gt 0 ]; then
    printf '%s\n' "untracked-present"
  elif [ "$outside_total" -gt 0 ]; then
    printf '%s\n' "outside-batch-changes-present"
  else
    printf '%s\n' "all-files-clean"
  fi
}

print_outside_batch_changes() {
  local readiness="" reason="" line=""

  collect_outside_batch_changes
  readiness="$(resolve_outside_batch_readiness "$OUTSIDE_BATCH_TOTAL")"
  reason="$(resolve_outside_batch_reason "$OUTSIDE_BATCH_TOTAL")"
  printf '%s | readiness=%s | reason=%s | total=%s | tracked-modified=%s | untracked=%s\n' \
    "OUTSIDE-BATCHES" \
    "$readiness" \
    "$reason" \
    "$OUTSIDE_BATCH_TOTAL" \
    "$OUTSIDE_BATCH_TRACKED_MODIFIED" \
    "$OUTSIDE_BATCH_UNTRACKED"
  for line in "${OUTSIDE_BATCH_STATE_LINES[@]}"; do
    printf '%s\n' "$line"
  done
}

resolve_batch_next_action_fields() {
  local batch="$1"
  local reason="$2"
  local curated_subchange=""
  local curated_untracked_group=""
  local fallback_untracked_focus=""

  BATCH_ACTION_COMMAND=""
  BATCH_ACTION_FOCUS="(none)"

  compute_batch_status "$batch"

  case "$reason" in
    missing-files-present)
      if [ "${#BATCH_STATUS_MISSING_FILES[@]}" -gt 0 ]; then
        BATCH_ACTION_FOCUS="${BATCH_STATUS_MISSING_FILES[0]}"
        BATCH_ACTION_COMMAND="./scripts/verify/run-review-batch-checks.sh --split ${batch} --filter missing"
      fi
      ;;
    tracked-modified-present)
      if [ "${#BATCH_STATUS_TRACKED_MODIFIED_FILES[@]}" -gt 0 ]; then
        BATCH_ACTION_FOCUS="${BATCH_STATUS_TRACKED_MODIFIED_FILES[0]}"
        curated_subchange="$(resolve_next_curated_subchange_name "$batch" "$BATCH_ACTION_FOCUS" "tracked-modified" || true)"
        if [ -n "$curated_subchange" ]; then
          BATCH_ACTION_COMMAND="./scripts/verify/run-review-batch-checks.sh --note ${batch} --filter tracked-modified --name ${curated_subchange} --write $(default_note_write_path "$batch" "$curated_subchange" "tracked-modified")"
        elif ! memo_manifest_has_recorded_output "$batch" "tracked-modified"; then
          BATCH_ACTION_COMMAND="./scripts/verify/run-review-batch-checks.sh --memo ${batch} --filter tracked-modified --write $(default_memo_write_path "$batch" "tracked-modified")"
        elif [ "${#BATCH_STATUS_UNTRACKED_FILES[@]}" -gt 0 ]; then
          curated_untracked_group="$(resolve_next_pending_untracked_group_name "$batch" || true)"
          if [ -n "$curated_untracked_group" ]; then
            BATCH_ACTION_FOCUS="$(resolve_untracked_group_focus_file "$batch" "$curated_untracked_group" || true)"
            if [ -z "$BATCH_ACTION_FOCUS" ]; then
              BATCH_ACTION_FOCUS="${BATCH_STATUS_UNTRACKED_FILES[0]}"
            fi
            BATCH_ACTION_COMMAND="./scripts/verify/run-review-batch-checks.sh --note ${batch} --filter untracked --name ${curated_untracked_group} --write $(default_note_write_path "$batch" "$curated_untracked_group" "untracked")"
          elif ! memo_manifest_has_recorded_output "$batch" "untracked"; then
            BATCH_ACTION_FOCUS="${BATCH_STATUS_UNTRACKED_FILES[0]}"
            BATCH_ACTION_COMMAND="./scripts/verify/run-review-batch-checks.sh --memo ${batch} --filter untracked --write $(default_memo_write_path "$batch" "untracked")"
          else
            return 1
          fi
        else
          return 1
        fi
      fi
      ;;
    untracked-present)
      if [ "${#BATCH_STATUS_UNTRACKED_FILES[@]}" -gt 0 ]; then
        BATCH_ACTION_FOCUS="${BATCH_STATUS_UNTRACKED_FILES[0]}"
        curated_untracked_group="$(resolve_next_pending_untracked_group_name "$batch" || true)"
        if [ -n "$curated_untracked_group" ]; then
          BATCH_ACTION_FOCUS="$(resolve_untracked_group_focus_file "$batch" "$curated_untracked_group" || true)"
          if [ -z "$BATCH_ACTION_FOCUS" ]; then
            BATCH_ACTION_FOCUS="${BATCH_STATUS_UNTRACKED_FILES[0]}"
          fi
          BATCH_ACTION_COMMAND="./scripts/verify/run-review-batch-checks.sh --note ${batch} --filter untracked --name ${curated_untracked_group} --write $(default_note_write_path "$batch" "$curated_untracked_group" "untracked")"
        elif resolve_next_untracked_group_name "$batch" >/dev/null 2>&1; then
          if ! memo_manifest_has_recorded_output "$batch" "untracked"; then
            BATCH_ACTION_COMMAND="./scripts/verify/run-review-batch-checks.sh --memo ${batch} --filter untracked --write $(default_memo_write_path "$batch" "untracked")"
          else
            fallback_untracked_focus="$(resolve_first_unmapped_untracked_file "$batch" || true)"
            if [ -n "$fallback_untracked_focus" ]; then
              BATCH_ACTION_FOCUS="$fallback_untracked_focus"
              BATCH_ACTION_COMMAND="./scripts/verify/run-review-batch-checks.sh --split ${batch} --filter untracked"
            else
              return 1
            fi
          fi
        else
          BATCH_ACTION_COMMAND="./scripts/verify/run-review-batch-checks.sh --split ${batch} --filter untracked"
        fi
      fi
      ;;
  esac

  [ -n "$BATCH_ACTION_COMMAND" ]
}

build_batch_status_rows() {
  local batch readiness reason priority reason_priority summary_line

  BATCH_STATUS_ROWS=()

  for batch in batch-1 batch-2 batch-3 batch-4 batch-5; do
    compute_batch_status "$batch"
    readiness="$(resolve_batch_readiness "$BATCH_STATUS_MISSING" "$BATCH_STATUS_TRACKED_MODIFIED" "$BATCH_STATUS_UNTRACKED")"
    reason="$(resolve_batch_reason "$BATCH_STATUS_MISSING" "$BATCH_STATUS_TRACKED_MODIFIED" "$BATCH_STATUS_UNTRACKED")"
    priority="$(resolve_readiness_priority "$readiness")"
    reason_priority="$(resolve_reason_priority "$reason")"
    summary_line="$(printf '%s | readiness=%s | reason=%s | total=%s | existing=%s | missing=%s | clean=%s | tracked-modified=%s | untracked=%s' \
      "$batch" \
      "$readiness" \
      "$reason" \
      "$BATCH_STATUS_TOTAL" \
      "$BATCH_STATUS_EXISTING" \
      "$BATCH_STATUS_MISSING" \
      "$BATCH_STATUS_CLEAN" \
      "$BATCH_STATUS_TRACKED_MODIFIED" \
      "$BATCH_STATUS_UNTRACKED")"
    BATCH_STATUS_ROWS+=("${priority}|${reason_priority}|${batch}|${readiness}|${reason}|${summary_line}")
  done
}

resolve_first_batch_action_fields() {
  local row remainder
  local current_batch current_readiness current_reason

  build_batch_status_rows

  FIRST_ACTION_BATCH=""
  FIRST_ACTION_READINESS=""
  FIRST_ACTION_REASON=""
  FIRST_ACTION_COMMAND=""
  FIRST_ACTION_TOTAL=0
  FIRST_ACTION_TRACKED_MODIFIED=0
  FIRST_ACTION_UNTRACKED=0
  FIRST_ACTION_MISSING=0
  FIRST_ACTION_FOCUS="(none)"

  while IFS= read -r row; do
    [ -n "$row" ] || continue
    remainder="${row#*|}"
    remainder="${remainder#*|}"
    current_batch="${remainder%%|*}"
    remainder="${remainder#*|}"
    current_readiness="${remainder%%|*}"
    remainder="${remainder#*|}"
    current_reason="${remainder%%|*}"
    if ! resolve_batch_next_action_fields "$current_batch" "$current_reason"; then
      continue
    fi
    FIRST_ACTION_BATCH="$current_batch"
    FIRST_ACTION_READINESS="$current_readiness"
    FIRST_ACTION_REASON="$current_reason"
    FIRST_ACTION_COMMAND="$BATCH_ACTION_COMMAND"
    FIRST_ACTION_FOCUS="$BATCH_ACTION_FOCUS"
    FIRST_ACTION_TOTAL="$BATCH_STATUS_TOTAL"
    FIRST_ACTION_TRACKED_MODIFIED="$BATCH_STATUS_TRACKED_MODIFIED"
    FIRST_ACTION_UNTRACKED="$BATCH_STATUS_UNTRACKED"
    FIRST_ACTION_MISSING="$BATCH_STATUS_MISSING"
    break
  done < <(printf '%s\n' "${BATCH_STATUS_ROWS[@]}" | sort -t'|' -k1,1n -k2,2n -k3,3)

  if [ -z "$FIRST_ACTION_BATCH" ] && [ "${#BATCH_STATUS_ROWS[@]}" -gt 0 ]; then
    local outside_group_name=""
    local outside_landing_group_name=""
    collect_outside_batch_changes
    if [ "$OUTSIDE_BATCH_TOTAL" -gt 0 ]; then
      FIRST_ACTION_BATCH="outside-batches"
      FIRST_ACTION_READINESS="needs-batching"
      FIRST_ACTION_REASON="outside-batch-changes-present"
      FIRST_ACTION_TOTAL="$OUTSIDE_BATCH_TOTAL"
      FIRST_ACTION_TRACKED_MODIFIED="$OUTSIDE_BATCH_TRACKED_MODIFIED"
      FIRST_ACTION_UNTRACKED="$OUTSIDE_BATCH_UNTRACKED"
      FIRST_ACTION_MISSING=0
      outside_group_name="$(resolve_next_pending_outside_batch_group_name || true)"
      if [ -n "$outside_group_name" ]; then
        FIRST_ACTION_FOCUS="$(resolve_outside_batch_group_focus_file "$outside_group_name" || true)"
        if [ -z "$FIRST_ACTION_FOCUS" ]; then
          if [ "${#OUTSIDE_BATCH_TRACKED_MODIFIED_FILES[@]}" -gt 0 ]; then
            FIRST_ACTION_FOCUS="${OUTSIDE_BATCH_TRACKED_MODIFIED_FILES[0]}"
          elif [ "${#OUTSIDE_BATCH_UNTRACKED_FILES[@]}" -gt 0 ]; then
            FIRST_ACTION_FOCUS="${OUTSIDE_BATCH_UNTRACKED_FILES[0]}"
          fi
        fi
        FIRST_ACTION_COMMAND="./scripts/verify/run-review-batch-checks.sh --outside-batch-note --name ${outside_group_name} --write $(default_outside_batch_note_write_path "$outside_group_name")"
      elif ! memo_manifest_has_recorded_output "outside-batches" "outside-batch"; then
        if [ "${#OUTSIDE_BATCH_TRACKED_MODIFIED_FILES[@]}" -gt 0 ]; then
          FIRST_ACTION_FOCUS="${OUTSIDE_BATCH_TRACKED_MODIFIED_FILES[0]}"
        elif [ "${#OUTSIDE_BATCH_UNTRACKED_FILES[@]}" -gt 0 ]; then
          FIRST_ACTION_FOCUS="${OUTSIDE_BATCH_UNTRACKED_FILES[0]}"
        fi
        FIRST_ACTION_COMMAND="./scripts/verify/run-review-batch-checks.sh --outside-batch-memo --write $(default_outside_batch_memo_write_path)"
      else
        outside_landing_group_name="$(resolve_next_pending_outside_landing_batch_group_name || true)"
        if [ -n "$outside_landing_group_name" ]; then
          FIRST_ACTION_FOCUS="$(resolve_outside_batch_group_focus_file "$outside_landing_group_name" || true)"
          if [ -z "$FIRST_ACTION_FOCUS" ]; then
            FIRST_ACTION_FOCUS="$(resolve_outside_landing_batch_name "$outside_landing_group_name")"
          fi
          FIRST_ACTION_COMMAND="$(resolve_outside_landing_batch_next_command "$outside_landing_group_name")"
        else
          if [ "${#OUTSIDE_BATCH_TRACKED_MODIFIED_FILES[@]}" -gt 0 ]; then
            FIRST_ACTION_FOCUS="${OUTSIDE_BATCH_TRACKED_MODIFIED_FILES[0]}"
          elif [ "${#OUTSIDE_BATCH_UNTRACKED_FILES[@]}" -gt 0 ]; then
            FIRST_ACTION_FOCUS="${OUTSIDE_BATCH_UNTRACKED_FILES[0]}"
          fi
          FIRST_ACTION_COMMAND="echo no-pending-review-actions"
        fi
      fi
      return 0
    fi
    FIRST_ACTION_READINESS="ready"
    FIRST_ACTION_REASON="no-pending-review-actions"
    FIRST_ACTION_COMMAND="echo no-pending-review-actions"
    FIRST_ACTION_TOTAL=0
    FIRST_ACTION_TRACKED_MODIFIED=0
    FIRST_ACTION_UNTRACKED=0
    FIRST_ACTION_MISSING=0
    FIRST_ACTION_FOCUS="(none)"
  fi
}

resolve_batch_handoff_fields() {
  local batch="$1"
  local readiness="$2"
  local reason="$3"

  BATCH_HANDOFF_STATE=""
  BATCH_HANDOFF_NEXT="(none)"

  if [ "$readiness" = "blocked" ]; then
    BATCH_HANDOFF_STATE="blocked"
    BATCH_HANDOFF_NEXT="./scripts/verify/run-review-batch-checks.sh --split ${batch} --filter missing"
    return 0
  fi

  if resolve_batch_next_action_fields "$batch" "$reason"; then
    BATCH_HANDOFF_NEXT="$BATCH_ACTION_COMMAND"
    case "$BATCH_ACTION_COMMAND" in
      *" --note "*|*" --memo "*)
        BATCH_HANDOFF_STATE="pending-artifact"
        ;;
      *" --split "*)
        BATCH_HANDOFF_STATE="direct-review"
        ;;
      *)
        BATCH_HANDOFF_STATE="pending-run"
        ;;
    esac
    return 0
  fi

  BATCH_HANDOFF_STATE="complete"
  BATCH_HANDOFF_NEXT="echo no-pending-review-actions"
}

print_next_action_verbose() {
  resolve_first_batch_action_fields
  if [ -z "$FIRST_ACTION_BATCH" ] || [ "${FIRST_ACTION_COMMAND:-}" = "echo no-pending-review-actions" ]; then
    printf '%s | state=complete | next=%s\n' \
      "NEXT" \
      "$FIRST_ACTION_COMMAND"
    return 0
  fi
  printf '%s | batch=%s | readiness=%s | reason=%s | total=%s | tracked-modified=%s | untracked=%s | missing=%s | focus=%s | next=%s\n' \
    "NEXT" \
    "$FIRST_ACTION_BATCH" \
    "$FIRST_ACTION_READINESS" \
    "$FIRST_ACTION_REASON" \
    "$FIRST_ACTION_TOTAL" \
    "$FIRST_ACTION_TRACKED_MODIFIED" \
    "$FIRST_ACTION_UNTRACKED" \
    "$FIRST_ACTION_MISSING" \
    "$FIRST_ACTION_FOCUS" \
    "$FIRST_ACTION_COMMAND"
}

compute_batch_status() {
  local batch="$1"
  local file state

  BATCH_STATUS_TOTAL=0
  BATCH_STATUS_EXISTING=0
  BATCH_STATUS_MISSING=0
  BATCH_STATUS_CLEAN=0
  BATCH_STATUS_TRACKED_MODIFIED=0
  BATCH_STATUS_UNTRACKED=0
  BATCH_STATUS_STATE_LINES=()
  BATCH_STATUS_MISSING_FILES=()
  BATCH_STATUS_TRACKED_MODIFIED_FILES=()
  BATCH_STATUS_UNTRACKED_FILES=()

  while IFS= read -r file; do
    [ -n "$file" ] || continue
    BATCH_STATUS_TOTAL=$((BATCH_STATUS_TOTAL + 1))
    state="$(resolve_git_file_state "$file")"
    case "$state" in
      clean)
        BATCH_STATUS_EXISTING=$((BATCH_STATUS_EXISTING + 1))
        BATCH_STATUS_CLEAN=$((BATCH_STATUS_CLEAN + 1))
        ;;
      tracked-modified)
        BATCH_STATUS_EXISTING=$((BATCH_STATUS_EXISTING + 1))
        BATCH_STATUS_TRACKED_MODIFIED=$((BATCH_STATUS_TRACKED_MODIFIED + 1))
        BATCH_STATUS_STATE_LINES+=("$batch | STATE | tracked-modified | $file")
        BATCH_STATUS_TRACKED_MODIFIED_FILES+=("$file")
        ;;
      untracked)
        BATCH_STATUS_EXISTING=$((BATCH_STATUS_EXISTING + 1))
        BATCH_STATUS_UNTRACKED=$((BATCH_STATUS_UNTRACKED + 1))
        BATCH_STATUS_STATE_LINES+=("$batch | STATE | untracked | $file")
        BATCH_STATUS_UNTRACKED_FILES+=("$file")
        ;;
      missing)
        BATCH_STATUS_MISSING=$((BATCH_STATUS_MISSING + 1))
        BATCH_STATUS_MISSING_FILES+=("$file")
        ;;
      *)
        echo "Unknown git file state for $file: $state" >&2
        exit 1
        ;;
    esac
  done < <(resolve_batch_files "$batch")
}

print_batch_status_summary() {
  local batch="$1"
  local readiness reason

  readiness="$(resolve_batch_readiness "$BATCH_STATUS_MISSING" "$BATCH_STATUS_TRACKED_MODIFIED" "$BATCH_STATUS_UNTRACKED")"
  reason="$(resolve_batch_reason "$BATCH_STATUS_MISSING" "$BATCH_STATUS_TRACKED_MODIFIED" "$BATCH_STATUS_UNTRACKED")"
  printf '%s | readiness=%s | reason=%s | total=%s | existing=%s | missing=%s | clean=%s | tracked-modified=%s | untracked=%s\n' \
    "$batch" \
    "$readiness" \
    "$reason" \
    "$BATCH_STATUS_TOTAL" \
    "$BATCH_STATUS_EXISTING" \
    "$BATCH_STATUS_MISSING" \
    "$BATCH_STATUS_CLEAN" \
    "$BATCH_STATUS_TRACKED_MODIFIED" \
    "$BATCH_STATUS_UNTRACKED"
}

print_batch_status() {
  local batch="$1"
  local readiness reason
  compute_batch_status "$batch"
  print_batch_status_summary "$batch"
  readiness="$(resolve_batch_readiness "$BATCH_STATUS_MISSING" "$BATCH_STATUS_TRACKED_MODIFIED" "$BATCH_STATUS_UNTRACKED")"
  reason="$(resolve_batch_reason "$BATCH_STATUS_MISSING" "$BATCH_STATUS_TRACKED_MODIFIED" "$BATCH_STATUS_UNTRACKED")"
  resolve_batch_handoff_fields "$batch" "$readiness" "$reason"
  printf '%s | HANDOFF | state=%s | next=%s\n' \
    "$batch" \
    "$BATCH_HANDOFF_STATE" \
    "$BATCH_HANDOFF_NEXT"
  for line in "${BATCH_STATUS_STATE_LINES[@]}"; do
    printf '%s\n' "$line"
  done
  for file in "${BATCH_STATUS_MISSING_FILES[@]}"; do
    printf '%s | MISSING | %s\n' "$batch" "$file"
  done
}

print_all_batch_status() {
  local batch readiness reason overall_readiness overall_reason
  local row remainder
  local total=0
  local existing=0
  local missing=0
  local clean=0
  local tracked_modified=0
  local untracked=0
  local ready=0
  local needs_landing=0
  local blocked=0
  local batches_with_missing=0
  local batches_with_tracked_modified=0
  local batches_with_untracked=0
  local handoff_complete=0
  local handoff_pending_artifact=0
  local handoff_direct_review=0
  local handoff_blocked=0
  local handoff_pending_run=0
  local batch_count=0
  local outside_total=0
  local outside_tracked_modified=0
  local outside_untracked=0
  local outside_readiness=""
  local outside_reason=""

  build_batch_status_rows

  for row in "${BATCH_STATUS_ROWS[@]}"; do
    remainder="${row#*|}"
    remainder="${remainder#*|}"
    batch="${remainder%%|*}"
    remainder="${remainder#*|}"
    readiness="${remainder%%|*}"
    compute_batch_status "$batch"
    batch_count=$((batch_count + 1))
    total=$((total + BATCH_STATUS_TOTAL))
    existing=$((existing + BATCH_STATUS_EXISTING))
    missing=$((missing + BATCH_STATUS_MISSING))
    clean=$((clean + BATCH_STATUS_CLEAN))
    tracked_modified=$((tracked_modified + BATCH_STATUS_TRACKED_MODIFIED))
    untracked=$((untracked + BATCH_STATUS_UNTRACKED))
    case "$readiness" in
      ready) ready=$((ready + 1)) ;;
      needs-landing) needs_landing=$((needs_landing + 1)) ;;
      blocked) blocked=$((blocked + 1)) ;;
    esac
    if [ "$BATCH_STATUS_MISSING" -gt 0 ]; then
      batches_with_missing=$((batches_with_missing + 1))
    fi
    if [ "$BATCH_STATUS_TRACKED_MODIFIED" -gt 0 ]; then
      batches_with_tracked_modified=$((batches_with_tracked_modified + 1))
    fi
    if [ "$BATCH_STATUS_UNTRACKED" -gt 0 ]; then
      batches_with_untracked=$((batches_with_untracked + 1))
    fi
    resolve_batch_handoff_fields "$batch" "$readiness" "$(resolve_batch_reason "$BATCH_STATUS_MISSING" "$BATCH_STATUS_TRACKED_MODIFIED" "$BATCH_STATUS_UNTRACKED")"
    case "$BATCH_HANDOFF_STATE" in
      complete) handoff_complete=$((handoff_complete + 1)) ;;
      pending-artifact) handoff_pending_artifact=$((handoff_pending_artifact + 1)) ;;
      direct-review) handoff_direct_review=$((handoff_direct_review + 1)) ;;
      blocked) handoff_blocked=$((handoff_blocked + 1)) ;;
      pending-run) handoff_pending_run=$((handoff_pending_run + 1)) ;;
    esac
  done

  resolve_first_batch_action_fields
  collect_outside_batch_changes
  outside_total="$OUTSIDE_BATCH_TOTAL"
  outside_tracked_modified="$OUTSIDE_BATCH_TRACKED_MODIFIED"
  outside_untracked="$OUTSIDE_BATCH_UNTRACKED"
  outside_readiness="$(resolve_outside_batch_readiness "$outside_total")"
  outside_reason="$(resolve_outside_batch_reason "$outside_total")"

  while IFS= read -r row; do
    [ -n "$row" ] || continue
    remainder="${row#*|}"
    remainder="${remainder#*|}"
    remainder="${remainder#*|}"
    remainder="${remainder#*|}"
    remainder="${remainder#*|}"
    printf '%s\n' "$remainder"
  done < <(printf '%s\n' "${BATCH_STATUS_ROWS[@]}" | sort -t'|' -k1,1n -k2,2n -k3,3)

  printf '%s | readiness=%s | reason=%s | total=%s | tracked-modified=%s | untracked=%s\n' \
    "OUTSIDE-BATCHES" \
    "$outside_readiness" \
    "$outside_reason" \
    "$outside_total" \
    "$outside_tracked_modified" \
    "$outside_untracked"

  if [ -n "$FIRST_ACTION_BATCH" ] && [ "${FIRST_ACTION_COMMAND:-}" != "echo no-pending-review-actions" ]; then
    printf '%s | batch=%s | readiness=%s | reason=%s | next=%s\n' \
      "FIRST-ACTION" \
      "$FIRST_ACTION_BATCH" \
      "$FIRST_ACTION_READINESS" \
      "$FIRST_ACTION_REASON" \
      "$FIRST_ACTION_COMMAND"
  fi

  overall_readiness="$(resolve_overall_review_readiness "$batches_with_missing" "$batches_with_tracked_modified" "$batches_with_untracked" "$outside_total")"
  overall_reason="$(resolve_overall_review_reason "$batches_with_missing" "$batches_with_tracked_modified" "$batches_with_untracked" "$outside_total")"
  printf '%s | complete=%s | pending-artifact=%s | direct-review=%s | pending-run=%s | blocked=%s | next=%s\n' \
    "HANDOFF" \
    "$handoff_complete" \
    "$handoff_pending_artifact" \
    "$handoff_direct_review" \
    "$handoff_pending_run" \
    "$handoff_blocked" \
    "${FIRST_ACTION_COMMAND:-echo no-pending-review-actions}"
  printf '%s | readiness=%s | reason=%s | ready=%s | needs-landing=%s | blocked=%s\n' \
    "VERDICT" \
    "$overall_readiness" \
    "$overall_reason" \
    "$ready" \
    "$needs_landing" \
    "$blocked"
  printf '%s | readiness=%s | reason=%s | batches=%s | total=%s | existing=%s | missing=%s | clean=%s | tracked-modified=%s | untracked=%s | batches-with-missing=%s | batches-with-tracked-modified=%s | batches-with-untracked=%s\n' \
    "ALL" \
    "$overall_readiness" \
    "$overall_reason" \
    "$batch_count" \
    "$total" \
    "$existing" \
    "$missing" \
    "$clean" \
    "$tracked_modified" \
    "$untracked" \
    "$batches_with_missing" \
    "$batches_with_tracked_modified" \
    "$batches_with_untracked"
}

run_batch_impl() {
  case "$1" in
    batch-1)
      (
        cd "$ROOT_DIR/facilitator"
        npm test -- --runInBand
      )
      ;;
    batch-2)
      bash "$ROOT_DIR/scripts/verify/run-cka-2026-regressions.sh" --list
      bash "$ROOT_DIR/scripts/verify/run-verify-contract-smokes.sh" \
        diagnostics-collector \
        diagnostics-pack \
        summary-renderer \
        review-handoff-pack
      ;;
    batch-3)
      (
        cd "$ROOT_DIR/scripts/verify"
        npm run --silent browser-ui-smoke:list
      )
      bash "$ROOT_DIR/scripts/verify/run-verify-contract-smokes.sh" browser-scenarios
      if [ "$RUN_FULL_BROWSER_UI_SMOKE" = "1" ]; then
        (
          cd "$ROOT_DIR/scripts/verify"
          npm run browser-ui-smoke
        )
      fi
      ;;
    batch-4)
      bash "$ROOT_DIR/scripts/verify/run-verify-contract-smokes.sh" workflow-contract
      bash "$ROOT_DIR/scripts/verify/review-batch-workflow-contract-smoke.sh"
      (
        cd "$ROOT_DIR"
        python3 - <<'PY'
import yaml
from pathlib import Path
for workflow in (
    Path('.github/workflows/ci.yml'),
    Path('.github/workflows/cka-2026-regressions.yml'),
    Path('.github/workflows/review-batch-checks.yml'),
):
    with workflow.open() as fh:
        yaml.safe_load(fh)
print('workflow yaml parse ok')
PY
      )
      ;;
    batch-5)
      grep -Fq 'Batch Validation Map' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq 'run-review-batch-checks.sh' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq 'run-review-batch-checks.sh' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq 'run-review-batch-checks.sh' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq -- '--split' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq -- '--split' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq -- '--split' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq -- '--untracked-groups' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq -- '--untracked-groups' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq -- '--untracked-groups' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq -- '--filter untracked' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq -- '--filter untracked' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq -- '--filter untracked' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq -- '--filter' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq -- '--filter' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq -- '--filter' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq -- '--diff' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq -- '--diff' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq -- '--diff' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq -- '--hunks' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq -- '--hunks' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq -- '--hunks' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq -- '--subchanges' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq -- '--subchanges' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq -- '--subchanges' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq -- '--memo' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq -- '--memo' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq -- '--memo' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq -- '--note' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq -- '--note' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq -- '--note' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq 'NOTE-WRITE' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq 'NOTE-WRITE' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq 'NOTE-WRITE' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq 'NOTE_MANIFEST_PATH' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq 'NOTE_MANIFEST_PATH' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq 'NOTE_MANIFEST_PATH' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq -- '--note-manifest' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq -- '--note-manifest' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq -- '--note-manifest' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq 'NOTE-MANIFEST' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq 'NOTE-MANIFEST' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq 'NOTE-MANIFEST' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq 'NOTE-LATEST' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq 'NOTE-LATEST' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq 'NOTE-LATEST' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq 'NOTE-SHOW' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq 'NOTE-SHOW' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq 'NOTE-SHOW' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq 'NOTE-CONTENT' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq 'NOTE-CONTENT' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq 'NOTE-CONTENT' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq -- '--landing-plan' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq -- '--landing-plan' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq -- '--landing-plan' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq -- '--landing-commands' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq -- '--landing-commands' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq -- '--landing-commands' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq 'LANDING-PLAN' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq 'LANDING-PLAN' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq 'LANDING-PLAN' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq 'LANDING-COMMANDS' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq 'LANDING-COMMANDS' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq 'LANDING-COMMANDS' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq 'MEMO_MANIFEST_PATH' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq 'MEMO_MANIFEST_PATH' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq 'MEMO_MANIFEST_PATH' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq -- '--memo-manifest' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq -- '--memo-manifest' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq -- '--memo-manifest' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq 'MEMO-MANIFEST' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq 'MEMO-MANIFEST' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq 'MEMO-MANIFEST' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq 'MEMO-LATEST' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq 'MEMO-LATEST' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq 'MEMO-LATEST' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq 'MEMO-SHOW' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq 'MEMO-SHOW' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq 'MEMO-SHOW' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq 'MEMO-CONTENT' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq 'MEMO-CONTENT' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq 'MEMO-CONTENT' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq -- '--write' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq -- '--write' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq -- '--write' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq -- '--name' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq -- '--name' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq -- '--name' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq -- '--detail' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq -- '--detail' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq -- '--detail' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq -- '--status' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq -- '--status' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq -- '--status' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq -- '--status-all' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq -- '--status-all' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq -- '--status-all' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq -- '--outside-batches' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq -- '--outside-batches' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq -- '--outside-batches' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq -- '--outside-batch-groups' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq -- '--outside-batch-groups' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq -- '--outside-batch-groups' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq -- '--outside-batch-plan' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq -- '--outside-batch-plan' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq -- '--outside-batch-plan' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq -- '--outside-batch-note' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq -- '--outside-batch-note' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq -- '--outside-batch-note' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq -- '--outside-batch-memo' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq -- '--outside-batch-memo' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq -- '--outside-batch-memo' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq -- '--next' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq -- '--next' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq -- '--next' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq -- '--next --verbose' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq -- '--next --verbose' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq -- '--next --verbose' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq 'OUTSIDE-BATCHES' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq 'OUTSIDE-BATCHES' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq 'OUTSIDE-BATCHES' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq 'OUTSIDE-BATCH-GROUP' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq 'OUTSIDE-BATCH-GROUP' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq 'OUTSIDE-BATCH-GROUP' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq 'OUTSIDE-LANDING-STEP' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq 'OUTSIDE-LANDING-STEP' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq 'OUTSIDE-LANDING-STEP' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq 'outside-batches-' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq 'outside-batches-' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq 'outside-batches-' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq 'review-notes' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq 'review-notes' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq 'review-notes' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq 'FIRST-ACTION' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq 'FIRST-ACTION' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq 'FIRST-ACTION' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      grep -Fq 'NEXT' "$ROOT_DIR/docs/reports/review-inventory-2026-04-10.md"
      grep -Fq 'NEXT' "$ROOT_DIR/scripts/verify/README.md"
      grep -Fq 'NEXT' "$ROOT_DIR/docs/reports/codebase-audit-2026-04-10.md"
      ;;
    *)
      echo "Unknown review batch: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
}

run_batch() {
  local batch="$1"
  local started_at elapsed exit_code

  started_at="$(date +%s)"
  set +e
  if [ "$BATCH_TIMEOUT_SECONDS" -gt 0 ] && command -v timeout >/dev/null 2>&1; then
    REVIEW_BATCH_TARGET="$batch" \
      timeout --foreground "${BATCH_TIMEOUT_SECONDS}s" bash "$0" __run_batch__
    exit_code=$?
  else
    run_batch_impl "$batch"
    exit_code=$?
  fi
  set -e

  elapsed="$(( $(date +%s) - started_at ))"

  if [ "$exit_code" -eq 0 ]; then
    log "${batch} review checks completed successfully in ${elapsed}s"
    return 0
  fi

  if [ "$BATCH_TIMEOUT_SECONDS" -gt 0 ] && [ "$exit_code" -eq 124 ]; then
    log "${batch} review checks timed out after ${BATCH_TIMEOUT_SECONDS}s"
  else
    log "${batch} review checks failed after ${elapsed}s with exit code ${exit_code}"
  fi

  return "$exit_code"
}

if [ "${1:-}" = "__run_batch__" ]; then
  if [ -z "${REVIEW_BATCH_TARGET:-}" ]; then
    echo "REVIEW_BATCH_TARGET is required for __run_batch__" >&2
    exit 1
  fi
  run_batch_impl "$REVIEW_BATCH_TARGET"
  exit 0
fi

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  usage
  exit 0
fi

if ! [[ "$BATCH_TIMEOUT_SECONDS" =~ ^[0-9]+$ ]]; then
  echo "BATCH_TIMEOUT_SECONDS must be a non-negative integer: $BATCH_TIMEOUT_SECONDS" >&2
  exit 1
fi

if [ "${1:-}" = "--list" ]; then
  printf '%s\n' \
    batch-1 \
    batch-2 \
    batch-3 \
    batch-4 \
    batch-5
  exit 0
fi

if [ "${1:-}" = "--describe" ]; then
  for batch in batch-1 batch-2 batch-3 batch-4 batch-5; do
    describe_batch "$batch"
  done
  exit 0
fi

if [ "${1:-}" = "--files" ]; then
  shift
  if [ "$#" -eq 0 ]; then
    set -- batch-1 batch-2 batch-3 batch-4 batch-5
  fi
  for batch in "$@"; do
    print_batch_files "$batch"
  done
  exit 0
fi

if [ "${1:-}" = "--split" ]; then
  shift
  split_filter=""
  split_batches=()
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --filter)
        shift
        if [ "$#" -eq 0 ]; then
          echo "--filter requires a state argument" >&2
          exit 1
        fi
        split_filter="$1"
        ;;
      *)
        split_batches+=("$1")
        ;;
    esac
    shift
  done
  if [ "${#split_batches[@]}" -eq 0 ]; then
    split_batches=(batch-1 batch-2 batch-3 batch-4 batch-5)
  fi
  if [ -n "$split_filter" ]; then
    validate_split_filter "$split_filter"
  fi
  for batch in "${split_batches[@]}"; do
    print_batch_split "$batch" "$split_filter"
  done
  exit 0
fi

if [ "${1:-}" = "--untracked-groups" ]; then
  shift
  untracked_group_name=""
  untracked_group_batches=()
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --name)
        shift
        if [ "$#" -eq 0 ]; then
          echo "--name requires a group identifier" >&2
          exit 1
        fi
        untracked_group_name="$1"
        ;;
      *)
        untracked_group_batches+=("$1")
        ;;
    esac
    shift
  done
  if [ "${#untracked_group_batches[@]}" -eq 0 ]; then
    untracked_group_batches=(batch-1 batch-2 batch-3 batch-4 batch-5)
  fi
  for batch in "${untracked_group_batches[@]}"; do
    print_batch_untracked_groups "$batch" "$untracked_group_name"
  done
  exit 0
fi

if [ "${1:-}" = "--diff" ]; then
  shift
  diff_filter="tracked-modified"
  diff_batches=()
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --filter)
        shift
        if [ "$#" -eq 0 ]; then
          echo "--filter requires a state argument" >&2
          exit 1
        fi
        diff_filter="$1"
        ;;
      *)
        diff_batches+=("$1")
        ;;
    esac
    shift
  done
  if [ "${#diff_batches[@]}" -eq 0 ]; then
    diff_batches=(batch-1 batch-2 batch-3 batch-4 batch-5)
  fi
  validate_diff_filter "$diff_filter"
  for batch in "${diff_batches[@]}"; do
    print_batch_diff "$batch" "$diff_filter"
  done
  exit 0
fi

if [ "${1:-}" = "--hunks" ]; then
  shift
  hunk_filter="tracked-modified"
  hunk_batches=()
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --filter)
        shift
        if [ "$#" -eq 0 ]; then
          echo "--filter requires a state argument" >&2
          exit 1
        fi
        hunk_filter="$1"
        ;;
      *)
        hunk_batches+=("$1")
        ;;
    esac
    shift
  done
  if [ "${#hunk_batches[@]}" -eq 0 ]; then
    hunk_batches=(batch-1 batch-2 batch-3 batch-4 batch-5)
  fi
  validate_hunk_filter "$hunk_filter"
  for batch in "${hunk_batches[@]}"; do
    print_batch_hunks "$batch" "$hunk_filter"
  done
  exit 0
fi

if [ "${1:-}" = "--subchanges" ]; then
  shift
  subchange_filter="tracked-modified"
  subchange_name=""
  subchange_detail="0"
  subchange_batches=()
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --filter)
        shift
        if [ "$#" -eq 0 ]; then
          echo "--filter requires a state argument" >&2
          exit 1
        fi
        subchange_filter="$1"
        ;;
      --name)
        shift
        if [ "$#" -eq 0 ]; then
          echo "--name requires a subchange identifier" >&2
          exit 1
        fi
        subchange_name="$1"
        ;;
      --detail)
        subchange_detail="1"
        ;;
      *)
        subchange_batches+=("$1")
        ;;
    esac
    shift
  done
  if [ "${#subchange_batches[@]}" -eq 0 ]; then
    subchange_batches=(batch-1 batch-2 batch-3 batch-4 batch-5)
  fi
  validate_subchange_filter "$subchange_filter"
  if [ "$subchange_detail" = "1" ] && [ -z "$subchange_name" ]; then
    echo "--detail requires --name <subchange>" >&2
    exit 1
  fi
  for batch in "${subchange_batches[@]}"; do
    print_batch_subchanges "$batch" "$subchange_filter" "$subchange_name" "$subchange_detail"
  done
  exit 0
fi

if [ "${1:-}" = "--note" ]; then
  shift
  note_filter="tracked-modified"
  note_name=""
  note_write_path=""
  note_output=""
  note_batches=()
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --filter)
        shift
        if [ "$#" -eq 0 ]; then
          echo "--filter requires a state argument" >&2
          exit 1
        fi
        note_filter="$1"
        ;;
      --name)
        shift
        if [ "$#" -eq 0 ]; then
          echo "--name requires a subchange or group identifier" >&2
          exit 1
        fi
        note_name="$1"
        ;;
      --write)
        shift
        if [ "$#" -eq 0 ]; then
          echo "--write requires a file path" >&2
          exit 1
        fi
        note_write_path="$1"
        ;;
      *)
        note_batches+=("$1")
        ;;
    esac
    shift
  done
  if [ "${#note_batches[@]}" -eq 0 ]; then
    note_batches=(batch-1 batch-2 batch-3 batch-4 batch-5)
  fi
  validate_note_filter "$note_filter"
  if [ -z "$note_name" ]; then
    echo "--note requires --name <subchange-or-group>" >&2
    exit 1
  fi
  note_output="$(
    for batch in "${note_batches[@]}"; do
      print_batch_note "$batch" "$note_filter" "$note_name"
    done
  )"
  printf '%s\n' "$note_output"
  if [ -n "$note_write_path" ]; then
    write_output_file "$note_write_path" "$note_output"
    append_note_manifest "$NOTE_MANIFEST_PATH" "$note_write_path" "$note_filter" "$note_name" "$(wc -c < "$note_write_path" | tr -d '[:space:]')" "${note_batches[@]}"
    printf '%s | path=%s | bytes=%s\n' \
      "NOTE-WRITE" \
      "$note_write_path" \
      "$(wc -c < "$note_write_path" | tr -d '[:space:]')"
    printf '%s | path=%s | entries=%s\n' \
      "NOTE-MANIFEST" \
      "$NOTE_MANIFEST_PATH" \
      "$(wc -l < "$NOTE_MANIFEST_PATH" | tr -d '[:space:]')"
  fi
  exit 0
fi

if [ "${1:-}" = "--note-manifest" ]; then
  shift
  note_manifest_latest="0"
  note_manifest_show="0"
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --latest)
        note_manifest_latest="1"
        ;;
      --show)
        note_manifest_show="1"
        ;;
      *)
        echo "Unknown argument for --note-manifest: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
    shift
  done
  if [ "$note_manifest_show" = "1" ] && [ "$note_manifest_latest" = "0" ]; then
    note_manifest_latest="1"
  fi
  print_note_manifest "$note_manifest_latest" "$note_manifest_show"
  exit 0
fi

if [ "${1:-}" = "--memo" ]; then
  shift
  memo_filter="tracked-modified"
  memo_write_path=""
  memo_bytes="0"
  memo_batches=()
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --filter)
        shift
        if [ "$#" -eq 0 ]; then
          echo "--filter requires a state argument" >&2
          exit 1
        fi
        memo_filter="$1"
        ;;
      --write)
        shift
        if [ "$#" -eq 0 ]; then
          echo "--write requires a file path" >&2
          exit 1
        fi
        memo_write_path="$1"
        ;;
      *)
        memo_batches+=("$1")
        ;;
    esac
    shift
  done
  if [ "${#memo_batches[@]}" -eq 0 ]; then
    memo_batches=(batch-1 batch-2 batch-3 batch-4 batch-5)
  fi
  validate_memo_filter "$memo_filter"
  memo_output="$(
    for batch in "${memo_batches[@]}"; do
      print_batch_memo "$batch" "$memo_filter"
    done
  )"
  printf '%s\n' "$memo_output"
  if [ -n "$memo_write_path" ]; then
    write_output_file "$memo_write_path" "$memo_output"
    memo_bytes="$(wc -c < "$memo_write_path" | tr -d '[:space:]')"
    append_memo_manifest "$MEMO_MANIFEST_PATH" "$memo_write_path" "$memo_filter" "$memo_bytes" "${memo_batches[@]}"
    printf '%s | path=%s | bytes=%s\n' \
      "MEMO-WRITE" \
      "$memo_write_path" \
      "$memo_bytes"
    printf '%s | path=%s | entries=%s\n' \
      "MEMO-MANIFEST" \
      "$MEMO_MANIFEST_PATH" \
      "$(wc -l < "$MEMO_MANIFEST_PATH" | tr -d '[:space:]')"
  fi
  exit 0
fi

if [ "${1:-}" = "--memo-manifest" ]; then
  shift
  memo_manifest_latest="0"
  memo_manifest_show="0"
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --latest)
        memo_manifest_latest="1"
        ;;
      --show)
        memo_manifest_show="1"
        ;;
      *)
        echo "Unknown argument for --memo-manifest: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
    shift
  done
  if [ "$memo_manifest_show" = "1" ] && [ "$memo_manifest_latest" = "0" ]; then
    memo_manifest_latest="1"
  fi
  print_memo_manifest "$memo_manifest_latest" "$memo_manifest_show"
  exit 0
fi

if [ "${1:-}" = "--handoff-index" ]; then
  shift
  handoff_index_show="0"
  handoff_index_batches=()
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --show)
        handoff_index_show="1"
        ;;
      *)
        handoff_index_batches+=("$1")
        ;;
    esac
    shift
  done
  print_handoff_index "$handoff_index_show" "${handoff_index_batches[@]}"
  exit 0
fi

if [ "${1:-}" = "--landing-plan" ]; then
  shift
  landing_plan_show="0"
  landing_plan_batches=()
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --show)
        landing_plan_show="1"
        ;;
      *)
        landing_plan_batches+=("$1")
        ;;
    esac
    shift
  done
  print_landing_plan "$landing_plan_show" "${landing_plan_batches[@]}"
  exit 0
fi

if [ "${1:-}" = "--landing-commands" ]; then
  shift
  print_landing_commands "$@"
  exit 0
fi

if [ "${1:-}" = "--status" ]; then
  shift
  if [ "$#" -eq 0 ]; then
    set -- batch-1 batch-2 batch-3 batch-4 batch-5
  fi
  for batch in "$@"; do
    print_batch_status "$batch"
  done
  exit 0
fi

if [ "${1:-}" = "--status-all" ]; then
  print_all_batch_status
  exit 0
fi

if [ "${1:-}" = "--outside-batches" ]; then
  print_outside_batch_changes
  exit 0
fi

if [ "${1:-}" = "--outside-batch-groups" ]; then
  shift
  outside_group_name=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --name)
        shift
        if [ "$#" -eq 0 ]; then
          echo "--name requires a group name" >&2
          exit 1
        fi
        outside_group_name="$1"
        ;;
      *)
        echo "Unknown argument for --outside-batch-groups: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
    shift
  done
  print_outside_batch_groups "$outside_group_name"
  exit 0
fi

if [ "${1:-}" = "--outside-batch-plan" ]; then
  shift
  outside_plan_show="0"
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --show)
        outside_plan_show="1"
        ;;
      *)
        echo "Unknown argument for --outside-batch-plan: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
    shift
  done
  print_outside_batch_plan "$outside_plan_show"
  exit 0
fi

if [ "${1:-}" = "--outside-landing-batches" ]; then
  shift
  outside_landing_show="0"
  outside_landing_name=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --show)
        outside_landing_show="1"
        ;;
      --name)
        shift
        if [ "$#" -eq 0 ]; then
          echo "--name requires an outside landing batch name" >&2
          exit 1
        fi
        outside_landing_name="$1"
        ;;
      *)
        echo "Unknown argument for --outside-landing-batches: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
    shift
  done
  print_outside_landing_batches "$outside_landing_show" "$outside_landing_name"
  exit 0
fi

if [ "${1:-}" = "--outside-landing-draft" ]; then
  shift
  outside_landing_draft_name=""
  outside_landing_draft_write_path=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --name)
        shift
        if [ "$#" -eq 0 ]; then
          echo "--name requires an outside landing batch name" >&2
          exit 1
        fi
        outside_landing_draft_name="$1"
        ;;
      --write)
        shift
        if [ "$#" -eq 0 ]; then
          echo "--write requires a file path" >&2
          exit 1
        fi
        outside_landing_draft_write_path="$1"
        ;;
      *)
        echo "Unknown argument for --outside-landing-draft: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
    shift
  done
  draft_output="$(print_outside_landing_draft "$outside_landing_draft_name")"
  printf '%s\n' "$draft_output"
  if [ -n "$outside_landing_draft_write_path" ]; then
    write_output_file "$outside_landing_draft_write_path" "$draft_output"
    append_outside_landing_draft_manifest \
      "$OUTSIDE_LANDING_DRAFT_MANIFEST_PATH" \
      "$outside_landing_draft_write_path" \
      "$outside_landing_draft_name" \
      "$(wc -c < "$outside_landing_draft_write_path" | tr -d '[:space:]')"
    printf '%s | path=%s | bytes=%s\n' \
      "OUTSIDE-LANDING-DRAFT-WRITE" \
      "$outside_landing_draft_write_path" \
      "$(wc -c < "$outside_landing_draft_write_path" | tr -d '[:space:]')"
  fi
  exit 0
fi

if [ "${1:-}" = "--outside-batch-note" ]; then
  shift
  outside_note_name=""
  outside_note_write_path=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --name)
        shift
        if [ "$#" -eq 0 ]; then
          echo "--name requires a group name" >&2
          exit 1
        fi
        outside_note_name="$1"
        ;;
      --write)
        shift
        if [ "$#" -eq 0 ]; then
          echo "--write requires a file path" >&2
          exit 1
        fi
        outside_note_write_path="$1"
        ;;
      *)
        echo "Unknown argument for --outside-batch-note: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
    shift
  done
  if [ -z "$outside_note_name" ]; then
    echo "--outside-batch-note requires --name <group>" >&2
    exit 1
  fi
  outside_note_output="$(print_outside_batch_note "$outside_note_name")"
  printf '%s\n' "$outside_note_output"
  if [ -n "$outside_note_write_path" ]; then
    write_output_file "$outside_note_write_path" "$outside_note_output"
    append_note_manifest "$NOTE_MANIFEST_PATH" "$outside_note_write_path" "outside-batch" "$outside_note_name" "$(wc -c < "$outside_note_write_path" | tr -d '[:space:]')" "outside-batches"
    printf '%s | path=%s | bytes=%s\n' \
      "NOTE-WRITE" \
      "$outside_note_write_path" \
      "$(wc -c < "$outside_note_write_path" | tr -d '[:space:]')"
    printf '%s | path=%s | entries=%s\n' \
      "NOTE-MANIFEST" \
      "$NOTE_MANIFEST_PATH" \
      "$(wc -l < "$NOTE_MANIFEST_PATH" | tr -d '[:space:]')"
  fi
  exit 0
fi

if [ "${1:-}" = "--outside-batch-memo" ]; then
  shift
  outside_memo_write_path=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --write)
        shift
        if [ "$#" -eq 0 ]; then
          echo "--write requires a file path" >&2
          exit 1
        fi
        outside_memo_write_path="$1"
        ;;
      *)
        echo "Unknown argument for --outside-batch-memo: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
    shift
  done
  outside_memo_output="$(print_outside_batch_memo)"
  printf '%s\n' "$outside_memo_output"
  if [ -n "$outside_memo_write_path" ]; then
    write_output_file "$outside_memo_write_path" "$outside_memo_output"
    outside_memo_bytes="$(wc -c < "$outside_memo_write_path" | tr -d '[:space:]')"
    append_memo_manifest "$MEMO_MANIFEST_PATH" "$outside_memo_write_path" "outside-batch" "$outside_memo_bytes" "outside-batches"
    printf '%s | path=%s | bytes=%s\n' \
      "MEMO-WRITE" \
      "$outside_memo_write_path" \
      "$outside_memo_bytes"
    printf '%s | path=%s | entries=%s\n' \
      "MEMO-MANIFEST" \
      "$MEMO_MANIFEST_PATH" \
      "$(wc -l < "$MEMO_MANIFEST_PATH" | tr -d '[:space:]')"
  fi
  exit 0
fi

if [ "${1:-}" = "--next" ]; then
  if [ "${2:-}" = "--verbose" ]; then
    print_next_action_verbose
    exit 0
  fi
  if [ -n "${2:-}" ]; then
    echo "Unknown argument for --next: ${2:-}" >&2
    usage >&2
    exit 1
  fi
  resolve_first_batch_action_fields
  printf '%s\n' "$FIRST_ACTION_COMMAND"
  exit 0
fi

BATCHES=("$@")
if [ "${#BATCHES[@]}" -eq 0 ]; then
  BATCHES=(batch-1 batch-2 batch-3 batch-4 batch-5)
fi

for batch in "${BATCHES[@]}"; do
  log "Running ${batch} review checks"
  run_batch "$batch"
done

log "Selected review batch checks completed"
