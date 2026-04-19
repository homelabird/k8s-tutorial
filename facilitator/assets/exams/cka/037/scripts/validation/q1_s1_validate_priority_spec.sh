#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="priority-lab"
DEPLOYMENT="batch-api"

PRIORITY_CLASS_NAME="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.priorityClassName}')"
PRIORITYCLASS_YAML="$(kubectl get priorityclass ops-critical -o yaml)"

[ "${PRIORITY_CLASS_NAME}" = "ops-critical" ] || { echo "batch-api must use PriorityClass ops-critical"; exit 1; }
printf '%s\n' "${PRIORITYCLASS_YAML}" | grep -Eq '^value: 100000$' || { echo "ops-critical must keep value 100000"; exit 1; }
printf '%s\n' "${PRIORITYCLASS_YAML}" | grep -Eq '^preemptionPolicy: Never$' || { echo "ops-critical must keep preemptionPolicy Never"; exit 1; }
echo "${PRIORITYCLASS_YAML}" | grep -Eq '^globalDefault: (false)?$' >/dev/null 2>&1 || true

echo "Deployment batch-api uses the intended PriorityClass and the existing PriorityClass value and preemption policy remain correct"
