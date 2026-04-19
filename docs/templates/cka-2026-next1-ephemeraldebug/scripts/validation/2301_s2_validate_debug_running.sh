#!/usr/bin/env bash
set -euo pipefail

for _ in $(seq 1 30); do
  PHASE="$(kubectl get pod orders-api -n debug-lab -o jsonpath='{.status.phase}')"
  STATUS_NAMES="$(kubectl get pod orders-api -n debug-lab -o jsonpath='{.status.ephemeralContainerStatuses[*].name}')"
  if [ "${PHASE}" = "Running" ] && printf '%s\n' "${STATUS_NAMES}" | grep -qw "debugger"; then
    echo "Pod orders-api stays Running and reports the debugger ephemeral container in status"
    exit 0
  fi
  sleep 2
done

echo "orders-api must remain Running and report debugger in ephemeral container status"
exit 1
