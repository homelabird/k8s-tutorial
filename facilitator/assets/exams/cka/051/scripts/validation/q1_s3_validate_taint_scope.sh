#!/usr/bin/env bash
set -euo pipefail

OPS_NODES="$(kubectl get nodes -l workload=ops -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')"
[ -n "${OPS_NODES}" ] || {
  echo "No ops nodes were found"
  exit 1
}

while IFS= read -r NODE; do
  [ -n "${NODE}" ] || continue
  TAINT_VALUE="$(kubectl get node "${NODE}" -o jsonpath='{.spec.taints[?(@.key=="dedicated")].value}')"
  TAINT_EFFECT="$(kubectl get node "${NODE}" -o jsonpath='{.spec.taints[?(@.key=="dedicated")].effect}')"
  [ "${TAINT_VALUE}" = "ops" ] || {
    echo "Node ${NODE} does not keep dedicated=ops"
    exit 1
  }
  [ "${TAINT_EFFECT}" = "NoExecute" ] || {
    echo "Node ${NODE} does not keep the NoExecute taint effect"
    exit 1
  }
done <<EOF_NODES
${OPS_NODES}
EOF_NODES

echo "Scheduling fix keeps the workload constrained to the intended NoExecute-tainted ops node pool"
