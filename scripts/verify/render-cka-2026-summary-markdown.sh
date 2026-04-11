#!/usr/bin/env bash
set -euo pipefail

SUMMARY_PATH="${1:-}"

if [ -z "${SUMMARY_PATH}" ]; then
  printf 'Usage: %s <summary-path>\n' "$(basename "$0")" >&2
  exit 1
fi

if [ ! -f "${SUMMARY_PATH}" ]; then
  printf 'Summary file not found: %s\n' "${SUMMARY_PATH}" >&2
  exit 1
fi

awk '
function norm_key(text, normalized) {
  normalized = tolower(text)
  gsub(/[^a-z0-9]+/, "_", normalized)
  gsub(/^_+|_+$/, "", normalized)
  return normalized
}

function emit_overview(label, key) {
  if (meta[key] != "") {
    printf "- %s: `%s`\n", label, meta[key]
  }
}

function emit_context(label, key) {
  if (meta[key] != "") {
    printf "- %s: `%s`\n", label, meta[key]
  }
}

function emit_status_totals(label, pass_count, recovered_count, failed_count, unknown_count, summary) {
  summary = sprintf("%d PASS / %d RECOVERED / %d FAILED", pass_count + 0, recovered_count + 0, failed_count + 0)
  if (unknown_count + 0 > 0) {
    summary = summary sprintf(" / %d UNKNOWN", unknown_count + 0)
  }
  printf "- %s: `%s`\n", label, summary
}

function emit_optional_summary(label, value) {
  if (value != "") {
    printf "- %s: `%s`\n", label, value
  }
}

function truncate_value(text, limit,    trimmed) {
  if (length(text) <= limit) {
    return text
  }
  trimmed = substr(text, 1, limit - 3)
  sub(/[[:space:]]+$/, "", trimmed)
  return trimmed "..."
}

function status_priority(status) {
  if (status == "FAILED") {
    return 0
  }
  if (status == "RECOVERED") {
    return 1
  }
  if (status == "UNKNOWN") {
    return 2
  }
  return 3
}

function duration_seconds(text, duration_match) {
  if (match(text, /\(([0-9]+)s\)/, duration_match)) {
    return duration_match[1] + 0
  }
  return 0
}

function recovery_duration(text, duration_match) {
  if (match(text, /\(([0-9]+s)\)/, duration_match)) {
    return duration_match[1]
  }
  if (text ~ /unrecovered/) {
    return "unrecovered"
  }
  return ""
}

function failure_cause(text, cause_match) {
  if (match(text, /last failure q[0-9]+\/v[0-9]+ - (.*), recovery /, cause_match)) {
    return cause_match[1]
  }
  if (match(text, /^q[0-9]+\/v[0-9]+ - (.*)$/, cause_match)) {
    return cause_match[1]
  }
  return ""
}

function host_log_filename(host, normalized) {
  normalized = host
  gsub(/[^A-Za-z0-9._-]+/, "-", normalized)
  return normalized "-orchestration.log"
}

function sort_focus_entries(lines, statuses, durations, names, count,    i, j, tmp_line, tmp_status, tmp_duration, tmp_name, left_priority, right_priority) {
  for (i = 1; i <= count; i++) {
    for (j = i + 1; j <= count; j++) {
      left_priority = status_priority(statuses[i])
      right_priority = status_priority(statuses[j])

      if (left_priority > right_priority || \
          (left_priority == right_priority && left_priority == 1 && durations[i] < durations[j])) {
        tmp_line = lines[i]
        lines[i] = lines[j]
        lines[j] = tmp_line

        tmp_status = statuses[i]
        statuses[i] = statuses[j]
        statuses[j] = tmp_status

        tmp_duration = durations[i]
        durations[i] = durations[j]
        durations[j] = tmp_duration

        tmp_name = names[i]
        names[i] = names[j]
        names[j] = tmp_name
      }
    }
  }
}

function emit_read_next_for_status(status,    i, item_count) {
  delete read_items

  if (status == "FAILED" || status == "RECOVERED") {
    read_items[1] = "facilitator-exam-lifecycle.log"
    item_count = 1
    for (i = 1; i <= focus_host_count && item_count < 3; i++) {
      if (focus_host_names[i] != "") {
        read_items[++item_count] = host_log_filename(focus_host_names[i])
      }
    }
    if (item_count < 3) {
      read_items[++item_count] = "podman-compose.log"
    }
  } else if (status == "PASS") {
    read_items[1] = "facilitator-exam-lifecycle.log"
    read_items[2] = "current-exam.json"
    read_items[3] = "facilitator.clean.log"
    item_count = 3
  } else {
    item_count = (read_count > 3 ? 3 : read_count)
    for (i = 1; i <= item_count; i++) {
      read_items[i] = read_next[i]
    }
  }

  if (item_count == 0) {
    print "1. none"
    return
  }

  for (i = 1; i <= item_count; i++) {
    printf "%d. `%s`\n", i, read_items[i]
  }
}

function emit_additional_files_for_status(status,    i, item_count, display_count, remaining_count) {
  delete extra_items

  if (status == "FAILED" || status == "RECOVERED") {
    extra_items[1] = "podman-compose.log"
    extra_items[2] = "facilitator.clean.log"
    extra_items[3] = "current-exam.json"
    item_count = 3
  } else if (status == "PASS") {
    extra_items[1] = "jumphost-orchestration.log"
    extra_items[2] = "podman-compose.log"
    extra_items[3] = "jumphost-dns-orchestration.log"
    item_count = 3
  } else {
    item_count = 0
  }

  if (item_count == 0) {
    return
  }

  display_count = (item_count > 2 ? 2 : item_count)
  remaining_count = item_count - display_count

  printf "- Extra logs:"
  for (i = 1; i <= display_count; i++) {
    if (i == 1) {
      printf " `%s`", extra_items[i]
    } else {
      printf ", `%s`", extra_items[i]
    }
  }
  if (remaining_count > 0) {
    printf " + `%d more in archive`", remaining_count
  }
  printf "\n"
}

function overall_status(health) {
  if (health ~ /unrecovered/) {
    return "FAILED"
  }
  if (health ~ /recovery verified/) {
    return "RECOVERED"
  }
  if (health ~ /clean pass/) {
    return "PASS"
  }
  return "UNKNOWN"
}

function question_status(body, failed_count_match) {
  if (body ~ /latest attempt FAILED/) {
    return "FAILED"
  }
  if (match(body, /\/ ([0-9]+) failed/, failed_count_match) && failed_count_match[1] + 0 > 0) {
    return "RECOVERED"
  }
  if (body ~ /latest attempt PASSED/) {
    return "PASS"
  }
  return "UNKNOWN"
}

function host_status(prepare, verifications, cleanup, failed_count_match) {
  if (prepare != "0" || cleanup != "0") {
    return "FAILED"
  }
  if (match(verifications, /\/ ([0-9]+) failed/, failed_count_match) && failed_count_match[1] + 0 > 0) {
    return "RECOVERED"
  }
  if (prepare == "0" && cleanup == "0") {
    return "PASS"
  }
  return "UNKNOWN"
}

BEGIN {
  section = ""
}

$0 == "CKA 2026 Diagnostics Summary" {
  next
}

$0 == "" {
  section = ""
  next
}

$0 == "Read next:" {
  section = "read_next"
  next
}

$0 == "Question summary:" {
  section = "questions"
  next
}

$0 == "Key files:" {
  section = "key_files"
  next
}

match($0, /^Host: (.*)$/, host_match) {
  section = "host"
  current_host = host_match[1]
  host_order[++host_count] = current_host
  next
}

section == "read_next" && match($0, /^  [0-9]+\.[ ]+(.*)$/, read_match) {
  read_next[++read_count] = read_match[1]
  next
}

section == "questions" && match($0, /^  q([0-9]+): (.*)$/, question_match) {
  question_id[++question_count] = question_match[1]
  question_body[question_count] = question_match[2]
  next
}

section == "host" && match($0, /^  ([^:]+): (.*)$/, host_value_match) {
  host_values[current_host SUBSEP norm_key(host_value_match[1])] = host_value_match[2]
  next
}

section == "key_files" && match($0, /^  (.*)$/, file_match) {
  key_files[++key_file_count] = file_match[1]
  next
}

match($0, /^([^:]+): (.*)$/, meta_match) {
  meta[norm_key(meta_match[1])] = meta_match[2]
  next
}

END {
  verdict = overall_status(meta["overall_health"])

  for (i = 1; i <= question_count; i++) {
    question_status_value = question_status(question_body[i])
    question_duration = recovery_duration(question_body[i])
    question_duration_seconds = duration_seconds(question_body[i])
    question_cause = failure_cause(question_body[i])
    question_prefix = sprintf("- **%s**", question_status_value)
    if (question_cause != "" && question_status_value == "FAILED") {
      question_prefix = question_prefix sprintf(" cause `%s`", question_cause)
    }
    if (question_duration != "" && question_status_value == "RECOVERED") {
      question_prefix = question_prefix sprintf(" recovery `%s`", question_duration)
    }
    question_line = sprintf("%s `q%s`: %s", question_prefix, question_id[i], question_body[i])

    if (question_status_value == "PASS") {
      pass_question_lines[++pass_question_count] = question_line
      question_pass_count++
    } else {
      focus_question_lines[++focus_question_count] = question_line
      focus_question_statuses[focus_question_count] = question_status_value
      focus_question_durations[focus_question_count] = question_duration_seconds
      focus_question_names[focus_question_count] = question_id[i]
      if (question_status_value == "RECOVERED") {
        question_recovered_count++
        if (question_duration_seconds > slowest_question_recovery_seconds) {
          slowest_question_recovery_seconds = question_duration_seconds
          slowest_question_recovery = sprintf("q%s (%ss)", question_id[i], question_duration_seconds)
        }
      } else if (question_status_value == "FAILED") {
        question_failed_count++
      } else {
        question_unknown_count++
      }
    }
  }

  for (i = 1; i <= host_count; i++) {
    host = host_order[i]
    prepare = host_values[host SUBSEP "prepare_exam_env_exitcode"]
    verifications = host_values[host SUBSEP "verification_events"]
    last_failed = host_values[host SUBSEP "last_failed_verification"]
    recovery = host_values[host SUBSEP "recovery"]
    cleanup = host_values[host SUBSEP "cleanup_exam_env_exitcode"]

    if (prepare == "") {
      prepare = "missing"
    }
    if (verifications == "") {
      verifications = "unknown"
    }
    if (last_failed == "") {
      last_failed = "none"
    }
    if (recovery == "") {
      recovery = "none"
    }
    if (cleanup == "") {
      cleanup = "missing"
    }

    host_status_value = host_status(prepare, verifications, cleanup)
    host_duration = recovery_duration(recovery)
    host_duration_seconds = duration_seconds(recovery)
    host_cause = failure_cause(last_failed)
    host_prefix = sprintf("- **%s**", host_status_value)
    if (host_cause != "" && host_status_value == "FAILED") {
      host_prefix = host_prefix sprintf(" cause `%s`", host_cause)
    }
    if (host_duration != "" && host_status_value == "RECOVERED") {
      host_prefix = host_prefix sprintf(" recovery `%s`", host_duration)
    }
    host_line = sprintf("%s `%s`: prepare `%s`, verifications `%s`, last failed `%s`, recovery `%s`, cleanup `%s`", \
      host_prefix, host, prepare, verifications, last_failed, recovery, cleanup)

    if (host_status_value == "PASS") {
      pass_host_lines[++pass_host_count] = host_line
      host_pass_count++
    } else {
      focus_host_lines[++focus_host_count] = host_line
      focus_host_statuses[focus_host_count] = host_status_value
      focus_host_durations[focus_host_count] = host_duration_seconds
      focus_host_names[focus_host_count] = host
      if (host_status_value == "RECOVERED") {
        host_recovered_count++
        if (host_duration_seconds > slowest_host_recovery_seconds) {
          slowest_host_recovery_seconds = host_duration_seconds
          slowest_host_recovery = sprintf("%s (%ss)", host, host_duration_seconds)
        }
      } else if (host_status_value == "FAILED") {
        host_failed_count++
      } else {
        host_unknown_count++
      }
    }
  }

  print "## CKA 2026 Regression Summary"
  print ""
  printf "**Verdict: %s**", verdict
  if (meta["overall_health"] != "") {
    printf " %s\n", meta["overall_health"]
  } else {
    printf " overall health unavailable\n"
  }
  print ""
  print "### Snapshot"
  emit_overview("Summary suite", "summary_suite_id")
  emit_overview("Last evaluation score", "last_evaluation_score")
  emit_overview("Evaluation attempts", "evaluation_attempts")
  emit_overview("Evaluation score history", "evaluation_score_history")
  emit_status_totals("Question states", question_pass_count, question_recovered_count, question_failed_count, question_unknown_count)
  emit_status_totals("Host states", host_pass_count, host_recovered_count, host_failed_count, host_unknown_count)
  emit_optional_summary("Slowest question recovery", slowest_question_recovery)
  emit_optional_summary("Slowest host recovery", slowest_host_recovery)

  print ""
  print "<details>"
  print "<summary>Context</summary>"
  print ""
  emit_context("Summary exam ID", "summary_exam_id")
  emit_context("Current exam ID", "current_exam_id")
  emit_context("Recent exam IDs", "recent_exam_ids")
  emit_context("Current exam HTTP status", "current_exam_http_status")
  print ""
  print "<details>"
  print "<summary>Additional context</summary>"
  print ""
  if (meta["base_url"] != "" && meta["base_url"] != "http://127.0.0.1:30080") {
    emit_context("Base URL", "base_url")
  }
  emit_context("Generated", "generated")
  emit_additional_files_for_status(verdict)
  if (verdict == "FAILED" && meta["latest_facilitator_lifecycle_event"] != "") {
    printf "- Latest facilitator event: `%s`\n", truncate_value(meta["latest_facilitator_lifecycle_event"], 96)
  }
  print "</details>"
  print "</details>"

  print ""
  print "### Questions"
  if (question_count == 0) {
    print "- none"
  } else {
    sort_focus_entries(focus_question_lines, focus_question_statuses, focus_question_durations, focus_question_names, focus_question_count)

    if (focus_question_count == 0) {
      print "- No recovered or failed questions."
    } else {
      for (i = 1; i <= focus_question_count; i++) {
        print focus_question_lines[i]
      }
    }

    if (pass_question_count > 0) {
      print ""
      print "<details>"
      printf "<summary>Passing questions (%d)</summary>\n", pass_question_count
      print ""
      for (i = 1; i <= pass_question_count; i++) {
        print pass_question_lines[i]
      }
      print "</details>"
    }
  }

  print ""
  print "### Hosts"
  if (host_count == 0) {
    print "- none"
  } else {
    sort_focus_entries(focus_host_lines, focus_host_statuses, focus_host_durations, focus_host_names, focus_host_count)

    if (focus_host_count == 0) {
      print "- No recovered or failed hosts."
    } else {
      for (i = 1; i <= focus_host_count; i++) {
        print focus_host_lines[i]
      }
    }

    if (pass_host_count > 0) {
      print ""
      print "<details>"
      printf "<summary>Passing hosts (%d)</summary>\n", pass_host_count
      print ""
      for (i = 1; i <= pass_host_count; i++) {
        print pass_host_lines[i]
      }
      print "</details>"
    }
  }

  print ""
  print "### Read Next"
  emit_read_next_for_status(verdict)
}
' "${SUMMARY_PATH}"
