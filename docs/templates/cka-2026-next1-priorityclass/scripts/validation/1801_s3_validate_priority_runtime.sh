#!/usr/bin/env bash
set -euo pipefail

POD_PRIORITY_CLASS="$(kubectl get pods -n priority-lab -l app=batch-api -o jsonpath='{.items[0].spec.priorityClassName}')"
POD_PRIORITY_VALUE="$(kubectl get pods -n priority-lab -l app=batch-api -o jsonpath='{.items[0].spec.priority}')"

[ "${POD_PRIORITY_CLASS}" = "ops-critical" ] || { echo "The running Pod must use PriorityClass ops-critical"; exit 1; }
[ "${POD_PRIORITY_VALUE}" = "100000" ] || { echo "The running Pod must have numeric priority 100000"; exit 1; }

echo "The running Pod uses PriorityClass ops-critical with the expected numeric priority"
