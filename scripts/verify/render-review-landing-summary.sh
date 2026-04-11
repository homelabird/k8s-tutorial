#!/usr/bin/env bash
set -euo pipefail

LANDING_PLAN_PATH="${1:-}"
OUTSIDE_LANDING_PATH="${2:-}"
LANDING_COMMANDS_PATH="${3:-}"

if [ -z "$LANDING_PLAN_PATH" ]; then
  printf 'Usage: %s <landing-plan-expanded-path> [outside-landing-batches-expanded-path] [landing-commands-path]\n' "$(basename "$0")" >&2
  exit 1
fi

if [ ! -f "$LANDING_PLAN_PATH" ]; then
  printf 'Landing plan file not found: %s\n' "$LANDING_PLAN_PATH" >&2
  exit 1
fi

if [ -n "$OUTSIDE_LANDING_PATH" ] && [ ! -f "$OUTSIDE_LANDING_PATH" ]; then
  printf 'Outside landing batches file not found: %s\n' "$OUTSIDE_LANDING_PATH" >&2
  exit 1
fi

if [ -n "$LANDING_COMMANDS_PATH" ] && [ ! -f "$LANDING_COMMANDS_PATH" ]; then
  printf 'Landing commands file not found: %s\n' "$LANDING_COMMANDS_PATH" >&2
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

function remember_file(scope, kind, path,    key) {
  key = scope SUBSEP kind
  file_count[key]++
  files[key, file_count[key]] = path
}

function remember_command(scope, type, value) {
  if (type == "stage") {
    stage_command[scope] = value
  } else if (type == "commit") {
    commit_command[scope] = value
  } else if (type == "commit-title") {
    commit_title_value[scope] = value
  } else if (type == "pr-title") {
    pr_title_value[scope] = value
  } else if (type == "next") {
    next_command_value[scope] = value
  }
}

function preview_files(scope, kind, limit,    key, count, i, preview, remaining) {
  key = scope SUBSEP kind
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

function landing_verdict(ready, pending, blocked, outside_groups) {
  if (blocked + 0 > 0) {
    return "BLOCKED"
  }
  if (outside_groups + 0 > 0) {
    return "OUTSIDE LANDING PENDING"
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
  max_order = 0
  outside_max_order = 0
}

FILENAME == landing_plan_file && /^LANDING-PLAN \| batches=/ {
  total_batches = field_value($0, "batches") + 0
  next
}

FILENAME == landing_plan_file && /^batch-[0-9]+ \| LANDING-STEP \| / {
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

FILENAME == landing_plan_file && /^batch-[0-9]+ \| LANDING-HANDOFF \| / {
  split($0, parts, " \\| ")
  batch = trim(parts[1])
  handoff_next[batch] = field_value($0, "next")
  next
}

FILENAME == landing_plan_file && /^batch-[0-9]+ \| LANDING-FILE \| / {
  split($0, parts, " \\| ")
  remember_file(trim(parts[1]), trim(parts[3]), trim(parts[4]))
  next
}

FILENAME == landing_plan_file && /^batch-[0-9]+ \| LANDING-ARTIFACT \| / {
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

command_file != "" && FILENAME == command_file && / \| LANDING-COMMAND-STEP \| / {
  split($0, parts, " \\| ")
  scope = trim(parts[1])
  command_step_state[scope] = field_value($0, "state")
  command_commit_scope[scope] = field_value($0, "commit-scope")
  command_focus[scope] = field_value($0, "focus")
  next
}

command_file != "" && FILENAME == command_file && / \| LANDING-COMMAND \| / {
  split($0, parts, " \\| ")
  scope = trim(parts[1])
  value = field_value($0, "command")
  if (value == "") {
    value = field_value($0, "value")
  }
  remember_command(scope, field_value($0, "type"), value)
  next
}

FILENAME == landing_plan_file && /^LANDING-PLAN-SUMMARY \| / {
  ready_for_landing = field_value($0, "ready-for-landing") + 0
  pending_handoff = field_value($0, "pending-handoff") + 0
  blocked = field_value($0, "blocked") + 0
  next
}

outside_landing_file != "" && FILENAME == outside_landing_file && /^LANDING-PLAN \| batches=/ {
  outside_groups = field_value($0, "batches") + 0
  next
}

outside_landing_file != "" && FILENAME == outside_landing_file && /^outside-[a-z0-9-]+ \| LANDING-STEP \| / {
  split($0, parts, " \\| ")
  batch = trim(parts[1])
  order = field_value($0, "order") + 0

  outside_order[order] = batch
  if (order > outside_max_order) {
    outside_max_order = order
  }

  outside_focus[batch] = field_value($0, "focus")
  outside_landing_state[batch] = field_value($0, "landing-state")
  outside_readiness[batch] = field_value($0, "readiness")
  outside_handoff_state[batch] = field_value($0, "handoff")
  outside_artifact_state[batch] = field_value($0, "artifact-state")
  outside_commit_scope[batch] = field_value($0, "commit-scope")
  outside_total_files[batch] = field_value($0, "files") + 0
  outside_tracked[batch] = field_value($0, "tracked-modified") + 0
  outside_untracked[batch] = field_value($0, "untracked") + 0
  outside_missing[batch] = field_value($0, "missing") + 0

  outside_total_file_count += outside_total_files[batch]
  outside_total_tracked += outside_tracked[batch]
  outside_total_untracked += outside_untracked[batch]
  outside_total_missing += outside_missing[batch]
  next
}

outside_landing_file != "" && FILENAME == outside_landing_file && /^outside-[a-z0-9-]+ \| LANDING-HANDOFF \| / {
  split($0, parts, " \\| ")
  batch = trim(parts[1])
  outside_next[batch] = field_value($0, "next")
  next
}

outside_landing_file != "" && FILENAME == outside_landing_file && /^outside-[a-z0-9-]+ \| LANDING-FILE \| / {
  split($0, parts, " \\| ")
  remember_file(trim(parts[1]), trim(parts[3]), trim(parts[4]))
  next
}

outside_landing_file != "" && FILENAME == outside_landing_file && /^outside-[a-z0-9-]+ \| LANDING-ARTIFACT \| / {
  split($0, parts, " \\| ")
  batch = trim(parts[1])
  artifact_type = field_value($0, "type")
  artifact_path = field_value($0, "path")
  if (artifact_type == "latest-note") {
    outside_latest_note[batch] = artifact_path
  } else if (artifact_type == "latest-memo") {
    outside_latest_memo[batch] = artifact_path
  }
  next
}

outside_landing_file != "" && FILENAME == outside_landing_file && /^LANDING-PLAN-SUMMARY \| / {
  outside_ready = field_value($0, "ready-for-landing") + 0
  outside_pending = field_value($0, "pending-handoff") + 0
  outside_blocked = field_value($0, "blocked") + 0
  next
}

END {
  first_actionable_scope = ""
  first_pending_scope = ""
  for (order = 1; order <= max_order; order++) {
    batch = batch_order[order]
    if (batch != "" && command_step_state[batch] == "actionable") {
      first_actionable_scope = batch
      break
    }
  }
  if (first_actionable_scope == "" && outside_max_order > 0) {
    for (order = 1; order <= outside_max_order; order++) {
      batch = outside_order[order]
      if (batch != "" && command_step_state[batch] == "actionable") {
        first_actionable_scope = batch
        break
      }
    }
  }
  if (first_actionable_scope == "") {
    for (order = 1; order <= max_order; order++) {
      batch = batch_order[order]
      if (batch != "" && command_step_state[batch] != "" && command_step_state[batch] != "noop") {
        first_pending_scope = batch
        break
      }
    }
  }
  if (first_actionable_scope == "" && first_pending_scope == "" && outside_max_order > 0) {
    for (order = 1; order <= outside_max_order; order++) {
      batch = outside_order[order]
      if (batch != "" && command_step_state[batch] != "" && command_step_state[batch] != "noop") {
        first_pending_scope = batch
        break
      }
    }
  }

  print "## Review Landing Summary"
  print ""
  printf "**Verdict: %s**", landing_verdict(ready_for_landing, pending_handoff, blocked, outside_groups)
  if (blocked > 0) {
    printf " blocked batches remain\n"
  } else if (outside_groups > 0) {
    printf " outside-batch landing groups still need commit/PR landing\n"
  } else if (pending_handoff > 0) {
    printf " handoff artifacts are still incomplete for some batches\n"
  } else if (ready_for_landing > 0) {
    printf " all staged landing batches are ready\n"
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
  if (outside_groups > 0) {
    printf "- Outside groups: `%d`\n", outside_groups + 0
    printf "- Outside files: `%d total / %d tracked-modified / %d untracked / %d missing`\n", outside_total_file_count + 0, outside_total_tracked + 0, outside_total_untracked + 0, outside_total_missing + 0
  }
  if (command_file != "") {
    printf "- Landing command source: `%s`\n", command_file
  }
  print ""

  if (command_file != "") {
    print "### Next Landing Command"
    if (first_actionable_scope != "") {
      target_label = command_commit_scope[first_actionable_scope]
      if (command_focus[first_actionable_scope] != "") {
        target_label = command_focus[first_actionable_scope]
      }
      printf "- Target: **%s** `%s`\n", first_actionable_scope, target_label
      if (stage_command[first_actionable_scope] != "") {
        printf "- Stage: `%s`\n", stage_command[first_actionable_scope]
      }
      if (commit_command[first_actionable_scope] != "") {
        printf "- Commit: `%s`\n", commit_command[first_actionable_scope]
      }
      if (commit_title_value[first_actionable_scope] != "") {
        printf "- Commit title: `%s`\n", commit_title_value[first_actionable_scope]
      }
      if (pr_title_value[first_actionable_scope] != "") {
        printf "- PR title: `%s`\n", pr_title_value[first_actionable_scope]
      }
    } else if (first_pending_scope != "") {
      target_label = command_commit_scope[first_pending_scope]
      if (command_focus[first_pending_scope] != "") {
        target_label = command_focus[first_pending_scope]
      }
      printf "- Pending target: **%s** `%s`\n", first_pending_scope, target_label
      if (next_command_value[first_pending_scope] != "") {
        printf "- Next handoff: `%s`\n", next_command_value[first_pending_scope]
      }
    } else {
      print "- No actionable landing commands exported."
    }
    print ""
  }

  print "### Commit Order"
  print ""
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

  if (outside_groups > 0) {
    print "### Outside Landing Order"
    if (outside_latest_memo[outside_order[1]] != "") {
      printf "Grouped memo: `%s`\n", outside_latest_memo[outside_order[1]]
      print ""
    }
    for (order = 1; order <= outside_max_order; order++) {
      batch = outside_order[order]
      if (batch == "") {
        continue
      }

      printf "%d. **%s** focus `%s`\n", order, batch, outside_focus[batch]
      printf "   State: `%s`; readiness `%s`; handoff `%s`; artifact `%s`\n", outside_landing_state[batch], outside_readiness[batch], outside_handoff_state[batch], outside_artifact_state[batch]
      printf "   Files: `%d total / %d tracked-modified / %d untracked`\n", outside_total_files[batch], outside_tracked[batch], outside_untracked[batch]
      printf "   Handoff: `%s`\n", outside_next[batch]

      tracked_preview = preview_files(batch, "tracked-modified", 2)
      untracked_preview = preview_files(batch, "untracked", 2)
      if (tracked_preview != "") {
        printf "   Tracked files: %s\n", tracked_preview
      }
      if (untracked_preview != "") {
        printf "   Untracked files: %s\n", untracked_preview
      }
      if (outside_latest_note[batch] != "" || outside_latest_memo[batch] != "") {
        printf "   Latest artifacts:"
        if (outside_latest_note[batch] != "") {
          printf " note `%s`", outside_latest_note[batch]
        }
        if (outside_latest_memo[batch] != "") {
          if (outside_latest_note[batch] != "") {
            printf ";"
          }
          printf " memo `%s`", outside_latest_memo[batch]
        }
        printf "\n"
      }
      print ""
    }
  }
}
' landing_plan_file="$LANDING_PLAN_PATH" outside_landing_file="$OUTSIDE_LANDING_PATH" command_file="$LANDING_COMMANDS_PATH" "$LANDING_PLAN_PATH" ${OUTSIDE_LANDING_PATH:+"$OUTSIDE_LANDING_PATH"} ${LANDING_COMMANDS_PATH:+"$LANDING_COMMANDS_PATH"}
