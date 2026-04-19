#!/usr/bin/env bash
set -euo pipefail

ROLLOUT_FILE="/tmp/exam/q1/lifecycle-rollout-status.txt"
[ -f "${ROLLOUT_FILE}" ] || {
  echo "Lifecycle rollout status file not found"
  exit 1
}

grep -F 'successfully rolled out' "${ROLLOUT_FILE}" >/dev/null || {
  echo "Lifecycle rollout status file does not contain a successful rollout message"
  exit 1
}

echo "The rollout-status output is saved to the expected file"
