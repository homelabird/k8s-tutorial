#!/bin/bash
set -euo pipefail

LOG_FILE="/tmp/exam/q402/log-agent-previous.log"
TOP_FILE="/tmp/exam/q402/ops-api-top.txt"

[ -f "$LOG_FILE" ] || { echo "Expected previous log evidence at $LOG_FILE"; exit 1; }
[ -f "$TOP_FILE" ] || { echo "Expected kubectl top evidence at $TOP_FILE"; exit 1; }

grep -Fq 'FATAL: log target /var/log/missing.log not found' "$LOG_FILE" || {
  echo "Previous log evidence must contain the crashing sidecar message"
  exit 1
}

grep -Fq 'ops-api' "$TOP_FILE" || {
  echo "kubectl top evidence must reference the ops-api pod"
  exit 1
}

grep -Eq '(^|[[:space:]])api([[:space:]]|$)' "$TOP_FILE" || {
  echo "kubectl top evidence must include the api container"
  exit 1
}

grep -Eq '(^|[[:space:]])log-agent([[:space:]]|$)' "$TOP_FILE" || {
  echo "kubectl top evidence must include the log-agent container"
  exit 1
}

echo "Log and resource evidence exports are present"
