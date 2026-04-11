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

function remember_artifact(scope, type, path) {
  if (type == "latest-note") {
    latest_note[scope] = path
  } else if (type == "latest-memo") {
    latest_memo[scope] = path
  }
}

function remember_command(scope, type, value) {
  if (type == "stage") {
    stage_command[scope] = value
  } else if (type == "commit") {
    commit_command[scope] = value
  } else if (type == "next") {
    next_command_value[scope] = value
  }
}

function print_command_section(scope,    printed) {
  if (command_step_state[scope] == "") {
    return
  }

  printed = 0
  print "Suggested shell commands:"
  print ""
  print "```bash"
  if (stage_command[scope] != "") {
    print stage_command[scope]
    printed = 1
  }
  if (commit_command[scope] != "") {
    print commit_command[scope]
    printed = 1
  }
  if (!printed && next_command_value[scope] != "") {
    print next_command_value[scope]
  }
  print "```"
  print ""
}

function commit_title(scope) {
  return "chore(review): land " scope " batch"
}

function pr_title(batch, scope) {
  return "Land " batch " (" scope ") handoff bundle"
}

BEGIN {
  max_order = 0
  outside_max_order = 0
}

FILENAME == landing_plan_file && /^batch-[0-9]+ \| LANDING-STEP \| / {
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

FILENAME == landing_plan_file && /^batch-[0-9]+ \| LANDING-HANDOFF \| / {
  split($0, parts, " \\| ")
  batch = trim(parts[1])
  next_action[batch] = field_value($0, "next")
  next
}

FILENAME == landing_plan_file && /^batch-[0-9]+ \| LANDING-FILE \| / {
  split($0, parts, " \\| ")
  remember_file(trim(parts[1]), trim(parts[3]), trim(parts[4]))
  next
}

FILENAME == landing_plan_file && /^batch-[0-9]+ \| LANDING-ARTIFACT \| / {
  split($0, parts, " \\| ")
  remember_artifact(trim(parts[1]), field_value($0, "type"), field_value($0, "path"))
  next
}

command_file != "" && FILENAME == command_file && / \| LANDING-COMMAND-STEP \| / {
  split($0, parts, " \\| ")
  scope = trim(parts[1])
  command_step_state[scope] = field_value($0, "state")
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

outside_landing_file != "" && FILENAME == outside_landing_file && /^LANDING-PLAN \| batches=/ {
  outside_groups = field_value($0, "batches") + 0
  next
}

outside_landing_file != "" && FILENAME == outside_landing_file && /^outside-[a-z0-9-]+ \| LANDING-STEP \| / {
  split($0, parts, " \\| ")
  group = trim(parts[1])
  order = field_value($0, "order") + 0

  outside_order[order] = group
  if (order > outside_max_order) {
    outside_max_order = order
  }

  outside_focus[group] = field_value($0, "focus")
  outside_landing_state[group] = field_value($0, "landing-state")
  outside_readiness[group] = field_value($0, "readiness")
  outside_handoff[group] = field_value($0, "handoff")
  outside_artifact_state[group] = field_value($0, "artifact-state")
  outside_total_files[group] = field_value($0, "files") + 0
  outside_tracked[group] = field_value($0, "tracked-modified") + 0
  outside_untracked[group] = field_value($0, "untracked") + 0
  next
}

outside_landing_file != "" && FILENAME == outside_landing_file && /^outside-[a-z0-9-]+ \| LANDING-HANDOFF \| / {
  split($0, parts, " \\| ")
  group = trim(parts[1])
  outside_next[group] = field_value($0, "next")
  next
}

outside_landing_file != "" && FILENAME == outside_landing_file && /^outside-[a-z0-9-]+ \| LANDING-FILE \| / {
  split($0, parts, " \\| ")
  remember_file(trim(parts[1]), trim(parts[3]), trim(parts[4]))
  next
}

outside_landing_file != "" && FILENAME == outside_landing_file && /^outside-[a-z0-9-]+ \| LANDING-ARTIFACT \| / {
  split($0, parts, " \\| ")
  remember_artifact(trim(parts[1]), field_value($0, "type"), field_value($0, "path"))
  next
}

END {
  print "## Review Landing Drafts"
  print ""
  printf "Generated from `%s`.\n", landing_plan_file
  if (outside_landing_file != "") {
    printf "Outside landing source: `%s`.\n", outside_landing_file
  }
  if (command_file != "") {
    printf "Landing command source: `%s`.\n", command_file
  }
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
    print_command_section(batch)
  }

  if (outside_groups > 0) {
    print "## Outside Landing Drafts"
    print ""
    for (order = 1; order <= outside_max_order; order++) {
      group = outside_order[order]
      if (group == "") {
        continue
      }

      print "### " group
      print ""
      printf "- Commit title: `%s`\n", commit_title(group)
      printf "- PR title: `Land %s handoff bundle`\n", group
      printf "- Landing state: `%s`\n", outside_landing_state[group]
      printf "- Readiness: `%s`\n", outside_readiness[group]
      printf "- Handoff: `%s`\n", outside_handoff[group]
      printf "- Artifact state: `%s`\n", outside_artifact_state[group]
      printf "- Focus: `%s`\n", outside_focus[group]
      printf "- File counts: `%d total / %d tracked-modified / %d untracked`\n", outside_total_files[group], outside_tracked[group], outside_untracked[group]
      printf "- Next command: `%s`\n", outside_next[group]
      if (latest_note[group] != "") {
        printf "- Latest note: `%s`\n", latest_note[group]
      }
      if (latest_memo[group] != "") {
        printf "- Grouped memo: `%s`\n", latest_memo[group]
      }
      print ""
      print "Files:"
      key = group SUBSEP "tracked-modified"
      for (i = 1; i <= file_count[key]; i++) {
        printf "- `tracked-modified`: `%s`\n", files[key, i]
      }
      key = group SUBSEP "untracked"
      for (i = 1; i <= file_count[key]; i++) {
        printf "- `untracked`: `%s`\n", files[key, i]
      }
      print ""
      print "Suggested PR body:"
      print ""
      print "```text"
      printf "Landing scope: %s\n", group
      printf "Group: %s\n", group
      printf "Focus: %s\n", outside_focus[group]
      printf "Handoff artifacts: note=%s memo=%s\n", latest_note[group], latest_memo[group]
      printf "Files: %d total, %d tracked-modified, %d untracked\n", outside_total_files[group], outside_tracked[group], outside_untracked[group]
      print "```"
      print ""
      print_command_section(group)
    }
  }
}
' landing_plan_file="$LANDING_PLAN_PATH" outside_landing_file="$OUTSIDE_LANDING_PATH" command_file="$LANDING_COMMANDS_PATH" "$LANDING_PLAN_PATH" ${OUTSIDE_LANDING_PATH:+"$OUTSIDE_LANDING_PATH"} ${LANDING_COMMANDS_PATH:+"$LANDING_COMMANDS_PATH"}
