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

function field_value(line, label,    pattern, match_text) {
  pattern = label "=([^|]+)"
  if (match(line, pattern, match_text)) {
    return trim(match_text[1])
  }
  return ""
}

function remember_file(batch, kind, path,    key) {
  key = batch SUBSEP kind
  file_count[key]++
  files[key, file_count[key]] = path
}

function preview_files(batch, kind, limit,    key, count, i, preview, remaining) {
  key = batch SUBSEP kind
  count = file_count[key] + 0
  if (count == 0) {
    return ""
  }

  preview = ""
  for (i = 1; i <= count && i <= limit; i++) {
    if (preview != "") {
      preview = preview ", "
    }
    preview = preview "`" files[key, i] "`"
  }

  remaining = count - limit
  if (remaining > 0) {
    preview = preview sprintf(", `+%d more`", remaining)
  }
  return preview
}

function landing_verdict(ready, pending, blocked) {
  if (blocked + 0 > 0) {
    return "BLOCKED"
  }
  if (pending + 0 > 0) {
    return "PENDING HANDOFF"
  }
  if (ready + 0 > 0) {
    return "READY FOR LANDING"
  }
  return "UNKNOWN"
}

BEGIN {
  total_batches = 0
  max_order = 0
}

/^LANDING-PLAN \| batches=/ {
  total_batches = field_value($0, "batches")
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

  landing_state[batch] = field_value($0, "landing-state")
  readiness[batch] = field_value($0, "readiness")
  handoff_state[batch] = field_value($0, "handoff")
  artifact_state[batch] = field_value($0, "artifact-state")
  commit_scope[batch] = field_value($0, "commit-scope")
  total_files[batch] = field_value($0, "files") + 0
  tracked_modified[batch] = field_value($0, "tracked-modified") + 0
  untracked[batch] = field_value($0, "untracked") + 0
  missing[batch] = field_value($0, "missing") + 0

  total_file_count += total_files[batch]
  total_tracked_modified += tracked_modified[batch]
  total_untracked += untracked[batch]
  total_missing += missing[batch]
  next
}

/^batch-[0-9]+ \| LANDING-HANDOFF \| / {
  split($0, parts, " \\| ")
  batch = trim(parts[1])
  handoff_next[batch] = field_value($0, "next")
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
  artifact_type = field_value($0, "type")
  artifact_path = field_value($0, "path")
  if (artifact_type == "latest-note") {
    latest_note[batch] = artifact_path
  } else if (artifact_type == "latest-memo") {
    latest_memo[batch] = artifact_path
  }
  next
}

/^LANDING-PLAN-SUMMARY \| / {
  ready_for_landing = field_value($0, "ready-for-landing") + 0
  pending_handoff = field_value($0, "pending-handoff") + 0
  blocked = field_value($0, "blocked") + 0
  next
}

END {
  print "## Review Landing Summary"
  print ""
  printf "**Verdict: %s**", landing_verdict(ready_for_landing, pending_handoff, blocked)
  if (blocked > 0) {
    printf " blocked batches remain\n"
  } else if (pending_handoff > 0) {
    printf " handoff artifacts are still incomplete for some batches\n"
  } else if (ready_for_landing > 0) {
    printf " all handoff artifacts are complete and the landing order is staged\n"
  } else {
    printf " landing state unavailable\n"
  }
  print ""
  print "### Snapshot"
  printf "- Batches: `%d`\n", total_batches + 0
  printf "- Ready for landing: `%d`\n", ready_for_landing + 0
  printf "- Pending handoff: `%d`\n", pending_handoff + 0
  printf "- Blocked: `%d`\n", blocked + 0
  printf "- File totals: `%d total / %d tracked-modified / %d untracked / %d missing`\n", total_file_count + 0, total_tracked_modified + 0, total_untracked + 0, total_missing + 0
  print ""
  print "### Commit Order"

  for (order = 1; order <= max_order; order++) {
    batch = batch_order[order]
    if (batch == "") {
      continue
    }

    printf "%d. **%s** `%s`\n", order, batch, commit_scope[batch]
    printf "   State: `%s`; readiness `%s`; handoff `%s`; artifact `%s`\n", landing_state[batch], readiness[batch], handoff_state[batch], artifact_state[batch]
    printf "   Files: `%d total / %d tracked-modified / %d untracked / %d missing`\n", total_files[batch], tracked_modified[batch], untracked[batch], missing[batch]
    printf "   Handoff: `%s`\n", handoff_next[batch]

    tracked_preview = preview_files(batch, "tracked-modified", 2)
    untracked_preview = preview_files(batch, "untracked", 3)
    missing_preview = preview_files(batch, "missing", 2)

    if (tracked_preview != "") {
      printf "   Tracked files: %s\n", tracked_preview
    }
    if (untracked_preview != "") {
      printf "   Untracked files: %s\n", untracked_preview
    }
    if (missing_preview != "") {
      printf "   Missing files: %s\n", missing_preview
    }
    if (latest_note[batch] != "" || latest_memo[batch] != "") {
      printf "   Latest artifacts:"
      if (latest_note[batch] != "") {
        printf " note `%s`", latest_note[batch]
      }
      if (latest_memo[batch] != "") {
        if (latest_note[batch] != "") {
          printf ";"
        }
        printf " memo `%s`", latest_memo[batch]
      }
      printf "\n"
    }
    print ""
  }
}
' "$LANDING_PLAN_PATH"
