#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://127.0.0.1:30080}"
OUTPUT_DIR="${1:-${OUTPUT_DIR:-.artifacts/cka-2026}}"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

strip_ansi_file() {
  local input_file="$1"
  local output_file="$2"

  sed -E 's/\x1B\[[0-9;]*[[:alpha:]]//g' "$input_file" >"$output_file" 2>/dev/null || cp "$input_file" "$output_file"
}

write_http_capture() {
  local url="$1"
  local body_file="$2"
  local status_file="$3"
  local headers_file="$4"

  curl -sS -D "$headers_file" -o "$body_file" -w '%{http_code}' "$url" >"$status_file" 2>"${body_file}.stderr" || true
}

collect_container_logs() {
  local container_name="$1"
  local output_file="$2"

  if sudo podman container exists "$container_name" 2>/dev/null; then
    sudo podman logs "$container_name" >"$output_file" 2>&1 || true
  else
    printf 'container-not-found\n' >"$output_file"
  fi
}

write_recent_exam_id_summary() {
  local input_file="$1"
  local output_file="$2"

  grep -Eo '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' "$input_file" \
    | tail -n 200 \
    | awk '!seen[$0]++' \
    | tail -n 10 >"$output_file" || true

  if [ ! -s "$output_file" ]; then
    printf 'no-exam-ids-found\n' >"$output_file"
  fi
}

write_facilitator_lifecycle_summary() {
  local input_file="$1"
  local output_file="$2"

  grep -E \
    'Exam created successfully|Started preparing environment|Successfully prepared environment|Exam environment set up successfully|Received request to evaluate exam|Received request to get exam result|Received request to end exam|Number of questions to evaluate|Evaluating question [0-9]+|Verification [0-9]+ for question [0-9]+: (PASSED|FAILED)|No current exam is set|Command : prepare-exam-env|Command : cleanup-exam-env|Executing command on jumphost .*: prepare-exam-env|Executing command on jumphost .*: cleanup-exam-env|Exam environment preparation completed successfully|Exam environment cleanup completed successfully' \
    "$input_file" >"$output_file" || true

  if [ ! -s "$output_file" ]; then
    printf 'no-facilitator-lifecycle-events-found\n' >"$output_file"
  fi
}

write_jumphost_orchestration_summary() {
  local input_file="$1"
  local host_name="$2"
  local output_file="$3"

  grep -E \
    "Executing command on jumphost ${host_name}: prepare-exam-env|Executing command on jumphost ${host_name}: cleanup-exam-env|Command : prepare-exam-env, result.*\"host\":\"${host_name}\"|Command : cleanup-exam-env, result.*\"host\":\"${host_name}\"|Verification [0-9]+ for question [0-9]+: (PASSED|FAILED).*\"host\":\"${host_name}\"" \
    "$input_file" >"$output_file" || true

  if [ ! -s "$output_file" ]; then
    printf 'no-jumphost-orchestration-events-found\n' >"$output_file"
  fi
}

host_log_slug() {
  printf '%s' "$1" | tr -c '[:alnum:]._-' '-'
}

host_orchestration_filename() {
  printf '%s-orchestration.log\n' "$(host_log_slug "$1")"
}

host_orchestration_path() {
  printf '%s/%s\n' "$OUTPUT_DIR" "$(host_orchestration_filename "$1")"
}

discover_hosts_for_exam() {
  local input_file="$1"
  local exam_id="$2"
  local output_file="$3"

  awk -v target_exam_id="$exam_id" '
    function emit_host(host) {
      if (host != "" && !seen[host]++) {
        ordered_hosts[++host_count] = host
      }
    }

    match($0, /Exam created successfully with ID: ([0-9a-f-]+)/, exam_match) {
      if (capture && exam_match[1] != target_exam_id) {
        exit
      }
      capture = (exam_match[1] == target_exam_id)
    }

    capture && match($0, /"host":"([^"]+)"/, host_match) {
      emit_host(host_match[1])
    }

    END {
      for (i = 1; i <= host_count; i++) {
        print ordered_hosts[i]
      }
    }
  ' "$input_file" >"$output_file" 2>/dev/null || true

  if [ ! -s "$output_file" ]; then
    grep -Eo '"host":"[^"]+"' "$input_file" \
      | sed -E 's/^"host":"([^"]+)"$/\1/' \
      | awk '!seen[$0]++' >"$output_file" 2>/dev/null || true
  fi

  if [ ! -s "$output_file" ]; then
    printf 'jumphost\n' >"$output_file"
  fi
}

latest_exit_code_for_host() {
  local input_file="$1"
  local command_name="$2"
  local host_name="$3"

  grep -E "Command : ${command_name}, result.*\"host\":\"${host_name}\"" "$input_file" \
    | tail -n 1 \
    | sed -n 's/.*"exitCode":\([-0-9]\+\).*/\1/p'
}

verification_count_for_host() {
  local input_file="$1"
  local verdict="$2"

  grep -c "Verification [0-9]\+ for question [0-9]\+: ${verdict}" "$input_file" 2>/dev/null || true
}

host_recovery_timeline_summary() {
  local input_file="$1"

  awk '
    function line_timestamp(line) {
      return substr(line, 1, 19)
    }

    match($0, /Verification [0-9]+ for question [0-9]+: FAILED/) {
      if (first_failed_at == "") {
        first_failed_at = line_timestamp($0)
      }
      next
    }

    first_failed_at != "" && first_recovered_at == "" && match($0, /Verification [0-9]+ for question [0-9]+: PASSED/) {
      first_recovered_at = line_timestamp($0)
    }

    END {
      if (first_failed_at == "") {
        print "none"
      } else if (first_recovered_at == "") {
        print first_failed_at " -> unrecovered"
      } else {
        start_cmd = "date -d \"" first_failed_at "\" +%s"
        end_cmd = "date -d \"" first_recovered_at "\" +%s"
        if ((start_cmd | getline start_epoch) > 0 && (end_cmd | getline end_epoch) > 0) {
          close(start_cmd)
          close(end_cmd)
          print first_failed_at " -> " first_recovered_at " (" (end_epoch - start_epoch) "s)"
        } else {
          close(start_cmd)
          close(end_cmd)
          print first_failed_at " -> " first_recovered_at
        }
      }
    }
  ' "$input_file"
}

pick_summary_exam_id() {
  local current_exam_id="$1"
  local fallback_exam_id

  if [ -n "$current_exam_id" ] && [ "$current_exam_id" != "no-active-exam-id" ]; then
    printf '%s\n' "$current_exam_id"
    return 0
  fi

  fallback_exam_id="$(tail -n 1 "$OUTPUT_DIR/facilitator-recent-exam-ids.txt" 2>/dev/null || true)"
  if [ -n "$fallback_exam_id" ] && [ "$fallback_exam_id" != "no-exam-ids-found" ]; then
    printf '%s\n' "$fallback_exam_id"
  fi
}

evaluation_attempt_count() {
  local input_file="$1"
  local exam_id="$2"

  if [ -z "$exam_id" ]; then
    printf '0\n'
    return 0
  fi

  grep -c "Received request to evaluate exam.*\"examId\":\"${exam_id}\"" "$input_file" 2>/dev/null || true
}

summary_suite_id_for_exam() {
  local input_file="$1"
  local exam_id="$2"

  if [ -z "$exam_id" ]; then
    return 0
  fi

  awk -v target_exam_id="$exam_id" '
    match($0, /"examId":"([^"]+)"/, suite_match) {
      pending_suite_id = suite_match[1]
    }
    match($0, /Exam created successfully with ID: ([0-9a-f-]+)/, exam_match) {
      if (pending_suite_id != "" && exam_match[1] == target_exam_id) {
        print pending_suite_id
        exit
      }
      pending_suite_id = ""
    }
  ' "$input_file"
}

latest_exam_score() {
  local input_file="$1"
  local exam_id="$2"

  if [ -z "$exam_id" ]; then
    return 0
  fi

  grep -E "Exam ${exam_id} evaluation completed with score: [0-9]+%" "$input_file" \
    | tail -n 1 \
    | sed -n 's/.*score: \([0-9]\+%\).*/\1/p'
}

exam_score_history() {
  local input_file="$1"
  local exam_id="$2"
  local history

  if [ -z "$exam_id" ]; then
    printf 'none\n'
    return 0
  fi

  history="$(grep -E "Exam ${exam_id} evaluation completed with score: [0-9]+%" "$input_file" \
    | sed -n 's/.*score: \([0-9]\+%\).*/\1/p' \
    | paste -sd ', ' - \
    | sed 's/,/, /g')"

  if [ -n "$history" ]; then
    printf '%s\n' "$history"
  else
    printf 'none\n'
  fi
}

verification_description_from_clean_log() {
  local input_file="$1"
  local host_name="$2"
  local question_id="$3"
  local verification_id="$4"

  awk \
    -v target_host="$host_name" \
    -v target_question="$question_id" \
    -v target_verification="$verification_id" '
      match($0, /Evaluating question ([0-9]+)/, q_match) {
        current_question = q_match[1]
      }
      match($0, /Verification ID: ([0-9]+)/, v_match) {
        current_verification = v_match[1]
      }
      match($0, /Description: (.*)\{"service":"facilitator-service"\}$/, d_match) {
        current_description = d_match[1]
      }
      index($0, "\"host\":\"" target_host "\"") && match($0, /Verification ([0-9]+) for question ([0-9]+): (PASSED|FAILED)/, result_match) {
        if (result_match[1] == target_verification && result_match[2] == target_question) {
          matched_description = current_description
        }
      }
      END {
        if (matched_description != "") {
          print matched_description
        }
      }
    ' "$input_file"
}

last_failed_verification_summary() {
  local input_file="$1"
  local clean_log_file="$2"
  local host_name="$3"
  local failed_line question_id verification_id message description

  failed_line="$(grep 'Verification [0-9]\+ for question [0-9]\+: FAILED' "$input_file" | tail -n 1 || true)"
  if [ -z "$failed_line" ]; then
    printf 'none\n'
    return 0
  fi

  question_id="$(printf '%s\n' "$failed_line" | sed -n 's/.*Verification \([0-9]\+\) for question \([0-9]\+\): FAILED.*/\2/p')"
  verification_id="$(printf '%s\n' "$failed_line" | sed -n 's/.*Verification \([0-9]\+\) for question \([0-9]\+\): FAILED.*/\1/p')"
  message="$(printf '%s\n' "$failed_line" | sed -n 's/.*"stdout":"\([^"]*\)".*/\1/p' | sed 's/\\n$//')"

  if [ -z "$message" ]; then
    message="$(printf '%s\n' "$failed_line" | sed -n 's/.*"stderr":"\([^"]*\)".*/\1/p' | sed 's/\\n$//')"
  fi

  if [ -z "$message" ]; then
    description="$(verification_description_from_clean_log "$clean_log_file" "$host_name" "$question_id" "$verification_id")"
  fi

  if [ -n "$message" ]; then
    printf 'q%s/v%s - %s\n' "$question_id" "$verification_id" "$message"
  elif [ -n "$description" ]; then
    printf 'q%s/v%s - %s\n' "$question_id" "$verification_id" "$description"
  else
    printf 'q%s/v%s - no failure message captured\n' "$question_id" "$verification_id"
  fi
}

question_verification_summary() {
  local input_file="$1"
  local exam_id="$2"
  local raw_summary q total_pass total_fail latest_pass latest_fail latest_outcome last_failed first_failed_at first_recovered_at timeline

  if [ -z "$exam_id" ]; then
    printf '  none\n'
    return 0
  fi

  raw_summary="$(
    awk -v target_exam_id="$exam_id" '
      function extract_field(line, key,    pattern, field_match) {
        pattern = "\"" key "\":\"([^\"]*)\""
        if (match(line, pattern, field_match)) {
          return field_match[1]
        }
        return ""
      }

      function line_timestamp(line) {
        return substr(line, 1, 19)
      }

      match($0, /Received request to evaluate exam.*"examId":"([^"]+)"/, exam_match) {
        active = (exam_match[1] == target_exam_id)
        if (active) {
          attempt++
        }
        next
      }
      active && index($0, "Exam " target_exam_id " evaluation completed with score:") {
        active = 0
        next
      }
      active && match($0, /Evaluating question ([0-9]+)/, question_match) {
        current_question = question_match[1]
      }
      active && match($0, /Verification ID: ([0-9]+)/, verification_id_match) {
        current_verification = verification_id_match[1]
      }
      active && match($0, /Description: (.*)\{"service":"facilitator-service"\}$/, description_match) {
        current_description = description_match[1]
      }
      active && match($0, /Verification ([0-9]+) for question ([0-9]+): (PASSED|FAILED)/, verification_match) {
        q = verification_match[2]
        verification_id = verification_match[1]
        verdict = verification_match[3]
        seen[q] = 1
        if (verdict == "PASSED") {
          total_pass[q]++
        } else {
          total_fail[q]++
          if (first_failed_at[q] == "") {
            first_failed_at[q] = line_timestamp($0)
          }
        }
        if (latest_attempt[q] != attempt) {
          latest_attempt[q] = attempt
          latest_pass[q] = 0
          latest_fail[q] = 0
        }
        if (verdict == "PASSED") {
          latest_pass[q]++
          if (first_failed_at[q] != "" && first_recovered_at[q] == "") {
            first_recovered_at[q] = line_timestamp($0)
          }
        } else {
          latest_fail[q]++
          failure_message = extract_field($0, "stdout")
          if (failure_message == "") {
            failure_message = extract_field($0, "stderr")
          }
          sub(/\\n$/, "", failure_message)
          if (failure_message == "") {
            failure_message = current_description
          }
          if (failure_message == "") {
            failure_message = "no failure message captured"
          }
          last_failed[q] = "q" q "/v" verification_id " - " failure_message
        }
      }
      END {
        for (q in seen) {
          printf "%s|%d|%d|%d|%d|%s|%s|%s\n", \
            q, total_pass[q] + 0, total_fail[q] + 0, latest_pass[q] + 0, latest_fail[q] + 0, \
            (last_failed[q] != "" ? last_failed[q] : "none"), \
            (first_failed_at[q] != "" ? first_failed_at[q] : "none"), \
            (first_recovered_at[q] != "" ? first_recovered_at[q] : "none")
        }
      }
    ' "$input_file" | sort -n -t'|' -k1,1
  )"

  if [ -z "$raw_summary" ]; then
    printf '  none\n'
    return 0
  fi

  while IFS='|' read -r q total_pass total_fail latest_pass latest_fail last_failed first_failed_at first_recovered_at; do
    if [ "${latest_fail}" -gt 0 ]; then
      latest_outcome="FAILED"
    elif [ "${latest_pass}" -gt 0 ]; then
      latest_outcome="PASSED"
    else
      latest_outcome="unknown"
    fi

    if [ "${first_failed_at}" = "none" ]; then
      timeline="none"
    elif [ "${first_recovered_at}" = "none" ]; then
      timeline="${first_failed_at} -> unrecovered"
    else
      if start_epoch="$(date -d "${first_failed_at}" +%s 2>/dev/null)" \
        && end_epoch="$(date -d "${first_recovered_at}" +%s 2>/dev/null)"; then
        timeline="${first_failed_at} -> ${first_recovered_at} ($((end_epoch - start_epoch))s)"
      else
        timeline="${first_failed_at} -> ${first_recovered_at}"
      fi
    fi

    printf '  q%s: %s passed / %s failed, latest attempt %s, last failure %s, recovery %s\n' \
      "$q" "$total_pass" "$total_fail" "$latest_outcome" "$last_failed" "$timeline"
  done <<<"$raw_summary"
}

overall_health_summary() {
  local question_summary="$1"
  local unrecovered recovered

  if [ -z "$question_summary" ] || [ "$question_summary" = "  none" ]; then
    printf 'unknown - no question verification summary available\n'
    return 0
  fi

  unrecovered="$(printf '%s\n' "$question_summary" | grep 'latest attempt FAILED' || true)"
  recovered="$(printf '%s\n' "$question_summary" | grep -v ' / 0 failed' | grep -v 'latest attempt FAILED' || true)"

  if [ -n "$unrecovered" ]; then
    printf 'unrecovered failures remain on the latest attempt\n'
  elif [ -n "$recovered" ]; then
    printf 'recovery verified after initial failures\n'
  else
    printf 'clean pass with no observed question failures\n'
  fi
}

write_bundle_summary() {
  local output_file="$1"
  local current_http_status current_exam_id summary_exam_id summary_suite_id recent_exam_ids latest_lifecycle
  local evaluation_attempts last_score score_history question_summary overall_health
  local host_name host_log_file prepare cleanup passed failed last_failed recovery
  local read_next_index

  current_http_status="$(cat "$OUTPUT_DIR/current-exam.status" 2>/dev/null || printf 'unknown')"
  current_exam_id="$(cat "$OUTPUT_DIR/current-exam-id.txt" 2>/dev/null || printf 'missing')"
  summary_exam_id="$(pick_summary_exam_id "$current_exam_id")"
  summary_suite_id="$(summary_suite_id_for_exam "$OUTPUT_DIR/facilitator.clean.log" "$summary_exam_id")"
  recent_exam_ids="$(paste -sd ', ' "$OUTPUT_DIR/facilitator-recent-exam-ids.txt" 2>/dev/null || printf 'none')"
  latest_lifecycle="$(tail -n 1 "$OUTPUT_DIR/facilitator-exam-lifecycle.log" 2>/dev/null || printf 'none')"
  evaluation_attempts="$(evaluation_attempt_count "$OUTPUT_DIR/facilitator.clean.log" "$summary_exam_id")"
  last_score="$(latest_exam_score "$OUTPUT_DIR/facilitator.clean.log" "$summary_exam_id")"
  score_history="$(exam_score_history "$OUTPUT_DIR/facilitator.clean.log" "$summary_exam_id")"
  question_summary="$(question_verification_summary "$OUTPUT_DIR/facilitator.clean.log" "$summary_exam_id")"
  overall_health="$(overall_health_summary "$question_summary")"

  {
    cat <<EOF
CKA 2026 Diagnostics Summary
Generated: $(date '+%Y-%m-%d %H:%M:%S')
Base URL: ${BASE_URL}
Current exam HTTP status: ${current_http_status}
Current exam ID: ${current_exam_id}
Summary exam ID: ${summary_exam_id:-none}
Summary suite ID: ${summary_suite_id:-unknown}
Recent exam IDs: ${recent_exam_ids}
Evaluation attempts: ${evaluation_attempts:-0}
Last evaluation score: ${last_score:-unknown}
Evaluation score history: ${score_history:-none}
Overall health: ${overall_health:-unknown}
Latest facilitator lifecycle event: ${latest_lifecycle}

Read next:
  1. facilitator-exam-lifecycle.log
EOF

    read_next_index=2
    while IFS= read -r host_name; do
      [ -n "$host_name" ] || continue
      printf '  %d. %s\n' "$read_next_index" "$(host_orchestration_filename "$host_name")"
      read_next_index=$((read_next_index + 1))
    done <"$OUTPUT_DIR/summary-hosts.txt"

    printf '  %d. podman-compose.log\n' "$read_next_index"
    read_next_index=$((read_next_index + 1))
    printf '  %d. facilitator.clean.log\n' "$read_next_index"

    cat <<EOF

Question summary:
${question_summary:-  none}
EOF

    while IFS= read -r host_name; do
      [ -n "$host_name" ] || continue
      host_log_file="$(host_orchestration_path "$host_name")"
      prepare="$(latest_exit_code_for_host "$host_log_file" "prepare-exam-env" "$host_name")"
      cleanup="$(latest_exit_code_for_host "$host_log_file" "cleanup-exam-env" "$host_name")"
      passed="$(verification_count_for_host "$host_log_file" "PASSED")"
      failed="$(verification_count_for_host "$host_log_file" "FAILED")"
      last_failed="$(last_failed_verification_summary "$host_log_file" "$OUTPUT_DIR/facilitator.clean.log" "$host_name")"
      recovery="$(host_recovery_timeline_summary "$host_log_file")"

      cat <<EOF

Host: ${host_name}
  prepare-exam-env exitCode: ${prepare:-missing}
  verification events: ${passed:-0} passed / ${failed:-0} failed
  last failed verification: ${last_failed:-none}
  recovery: ${recovery:-none}
  cleanup-exam-env exitCode: ${cleanup:-missing}
EOF
    done <"$OUTPUT_DIR/summary-hosts.txt"

    cat <<EOF

Key files:
  summary.txt
  facilitator-exam-lifecycle.log
EOF

    while IFS= read -r host_name; do
      [ -n "$host_name" ] || continue
      printf '  %s\n' "$(host_orchestration_filename "$host_name")"
    done <"$OUTPUT_DIR/summary-hosts.txt"

    cat <<EOF
  facilitator.clean.log
  podman-compose.log
  current-exam.json
EOF
  } >"$output_file"
}

mkdir -p "$OUTPUT_DIR"
log "Collecting CKA 2026 diagnostics into $OUTPUT_DIR"

sudo podman ps -a >"$OUTPUT_DIR/podman-ps.txt" 2>&1 || true
sudo podman images >"$OUTPUT_DIR/podman-images.txt" 2>&1 || true
sudo podman compose -f docker-compose.yaml -f docker-compose.podman.yaml ps -a >"$OUTPUT_DIR/podman-compose-ps.txt" 2>&1 || true
sudo podman compose -f docker-compose.yaml -f docker-compose.podman.yaml logs --no-color >"$OUTPUT_DIR/podman-compose.log" 2>&1 || true

collect_container_logs "k8s-tutorial_facilitator_1" "$OUTPUT_DIR/facilitator.log"
collect_container_logs "k8s-tutorial_jumphost_1" "$OUTPUT_DIR/jumphost.log"
collect_container_logs "k8s-tutorial_jumphost-dns_1" "$OUTPUT_DIR/jumphost-dns.log"
collect_container_logs "kind-cluster" "$OUTPUT_DIR/kind-cluster.log"
collect_container_logs "kind-cluster-dns" "$OUTPUT_DIR/kind-cluster-dns.log"

strip_ansi_file "$OUTPUT_DIR/facilitator.log" "$OUTPUT_DIR/facilitator.clean.log"
write_recent_exam_id_summary "$OUTPUT_DIR/facilitator.clean.log" "$OUTPUT_DIR/facilitator-recent-exam-ids.txt"
write_facilitator_lifecycle_summary "$OUTPUT_DIR/facilitator.clean.log" "$OUTPUT_DIR/facilitator-exam-lifecycle.log"

write_http_capture \
  "$BASE_URL/facilitator/api/v1/exams/current" \
  "$OUTPUT_DIR/current-exam.json" \
  "$OUTPUT_DIR/current-exam.status" \
  "$OUTPUT_DIR/current-exam.headers"

current_exam_id=""
if command -v jq >/dev/null 2>&1; then
  current_exam_id="$(jq -r '.examId // .id // empty' "$OUTPUT_DIR/current-exam.json" 2>/dev/null || true)"
fi

if [ -n "$current_exam_id" ]; then
  printf '%s\n' "$current_exam_id" >"$OUTPUT_DIR/current-exam-id.txt"
  write_http_capture \
    "$BASE_URL/facilitator/api/v1/exams/$current_exam_id/status" \
    "$OUTPUT_DIR/exam-status.json" \
    "$OUTPUT_DIR/exam-status.status" \
    "$OUTPUT_DIR/exam-status.headers"
  write_http_capture \
    "$BASE_URL/facilitator/api/v1/exams/$current_exam_id/questions" \
    "$OUTPUT_DIR/exam-questions.json" \
    "$OUTPUT_DIR/exam-questions.status" \
    "$OUTPUT_DIR/exam-questions.headers"
  write_http_capture \
    "$BASE_URL/facilitator/api/v1/exams/$current_exam_id/result" \
    "$OUTPUT_DIR/exam-result.json" \
    "$OUTPUT_DIR/exam-result.status" \
    "$OUTPUT_DIR/exam-result.headers"
else
  printf 'no-active-exam-id\n' >"$OUTPUT_DIR/current-exam-id.txt"
fi

summary_exam_id="$(pick_summary_exam_id "$current_exam_id")"
discover_hosts_for_exam "$OUTPUT_DIR/facilitator.clean.log" "$summary_exam_id" "$OUTPUT_DIR/summary-hosts.txt"

while IFS= read -r host_name; do
  [ -n "$host_name" ] || continue
  write_jumphost_orchestration_summary \
    "$OUTPUT_DIR/facilitator.clean.log" \
    "$host_name" \
    "$(host_orchestration_path "$host_name")"
done <"$OUTPUT_DIR/summary-hosts.txt"

write_bundle_summary "$OUTPUT_DIR/summary.txt"

log "Diagnostics collection completed"
