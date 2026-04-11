#!/usr/bin/env bash
set -euo pipefail

LANDING_PLAN_PATH="${1:-}"

if [ -z "$LANDING_PLAN_PATH" ]; then
  printf 'Usage: %s <landing-plan-expanded-path>\n' "$(basename "$0")" >&2
  exit 1
fi

if [ ! -f "$LANDING_PLAN_PATH" ]; then
  printf 'Landing plan file not found: %s\n' "$LANDING_PLAN_PATH" >&2
  exit 1
fi

awk '
function trim(text) {
  sub(/^[[:space:]]+/, "", text)
  sub(/[[:space:]]+$/, "", text)
  return text
}

function field_value(line, label,    start, rest, parts) {
  start = index(line, label "=")
  if (start == 0) {
    return ""
  }
  rest = substr(line, start + length(label) + 1)
  split(rest, parts, "|")
  return trim(parts[1])
}

function remember_file(batch, kind, path,    key) {
  key = batch SUBSEP kind
  file_count[key]++
  files[key, file_count[key]] = path
}

function remember_artifact(batch, type, path) {
  if (type == "latest-note") {
    latest_note[batch] = path
  } else if (type == "latest-memo") {
    latest_memo[batch] = path
  }
}

function commit_title(scope) {
  return "chore(review): land " scope " batch"
}

function pr_title(batch, scope) {
  return "Land " batch " (" scope ") handoff bundle"
}

BEGIN {
  total_batches = 0
  max_order = 0
}

/^LANDING-PLAN \| batches=/ {
  total_batches = field_value($0, "batches") + 0
  next
}

/^batch-[0-9]+ \| LANDING-STEP \| / {
  split($0, parts, " \\| ")
  batch = trim(parts[1])
  order = field_value($0, "order") + 0
  batch_order[order] = batch
  if (order > max_order) {
    max_order = order
  }
  commit_scope[batch] = field_value($0, "commit-scope")
  landing_state[batch] = field_value($0, "landing-state")
  readiness[batch] = field_value($0, "readiness")
  handoff_state[batch] = field_value($0, "handoff")
  artifact_state[batch] = field_value($0, "artifact-state")
  total_files[batch] = field_value($0, "files") + 0
  tracked_modified[batch] = field_value($0, "tracked-modified") + 0
  untracked[batch] = field_value($0, "untracked") + 0
  missing[batch] = field_value($0, "missing") + 0
  next
}

/^batch-[0-9]+ \| LANDING-HANDOFF \| / {
  split($0, parts, " \\| ")
  batch = trim(parts[1])
  next_action[batch] = field_value($0, "next")
  next
}

/^batch-[0-9]+ \| LANDING-FILE \| / {
  split($0, parts, " \\| ")
  batch = trim(parts[1])
  kind = trim(parts[3])
  path = trim(parts[4])
  remember_file(batch, kind, path)
  next
}

/^batch-[0-9]+ \| LANDING-ARTIFACT \| / {
  split($0, parts, " \\| ")
  batch = trim(parts[1])
  remember_artifact(batch, field_value($0, "type"), field_value($0, "path"))
  next
}

END {
  print "## Review Landing Drafts"
  print ""
  printf "Generated from `%s`.\n", LANDING_PLAN_PATH
  print ""
  print "Use one section per landing commit or PR draft."
  print ""

  for (order = 1; order <= max_order; order++) {
    batch = batch_order[order]
    if (batch == "") {
      continue
    }

    scope = commit_scope[batch]
    print "### " batch
    print ""
    printf "- Commit title: `%s`\n", commit_title(scope)
    printf "- PR title: `%s`\n", pr_title(batch, scope)
    printf "- Landing state: `%s`\n", landing_state[batch]
    printf "- Readiness: `%s`\n", readiness[batch]
    printf "- Handoff: `%s`\n", handoff_state[batch]
    printf "- Artifact state: `%s`\n", artifact_state[batch]
    printf "- File counts: `%d total / %d tracked-modified / %d untracked / %d missing`\n", total_files[batch], tracked_modified[batch], untracked[batch], missing[batch]
    printf "- Next command: `%s`\n", next_action[batch]
    if (latest_note[batch] != "") {
      printf "- Latest note: `%s`\n", latest_note[batch]
    }
    if (latest_memo[batch] != "") {
      printf "- Latest memo: `%s`\n", latest_memo[batch]
    }
    print ""
    print "Files:"
    key = batch SUBSEP "tracked-modified"
    for (i = 1; i <= file_count[key]; i++) {
      printf "- `tracked-modified`: `%s`\n", files[key, i]
    }
    key = batch SUBSEP "untracked"
    for (i = 1; i <= file_count[key]; i++) {
      printf "- `untracked`: `%s`\n", files[key, i]
    }
    key = batch SUBSEP "missing"
    for (i = 1; i <= file_count[key]; i++) {
      printf "- `missing`: `%s`\n", files[key, i]
    }
    print ""
    print "Suggested PR body:"
    print ""
    print "```text"
    printf "Landing scope: %s\n", scope
    printf "Batch: %s\n", batch
    printf "Readiness: %s\n", readiness[batch]
    printf "Handoff artifacts: note=%s memo=%s\n", latest_note[batch], latest_memo[batch]
    printf "Files: %d total, %d tracked-modified, %d untracked, %d missing\n", total_files[batch], tracked_modified[batch], untracked[batch], missing[batch]
    print "```"
    print ""
  }
}
' LANDING_PLAN_PATH="$LANDING_PLAN_PATH" "$LANDING_PLAN_PATH"
