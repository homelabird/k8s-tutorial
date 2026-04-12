#!/bin/bash
set -euo pipefail

NAMESPACE="scheduling-lab"
DEPLOYMENT="metrics-agent"

OPS_NODES="$(kubectl get nodes -l workload=ops -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')"
[ -n "$OPS_NODES" ] || {
  echo "No nodes labeled workload=ops were found"
  exit 1
}

while IFS= read -r NODE; do
  [ -n "$NODE" ] || continue
  TAINT_VALUE="$(kubectl get node "$NODE" -o jsonpath='{.spec.taints[?(@.key=="dedicated")].value}')"
  TAINT_EFFECT="$(kubectl get node "$NODE" -o jsonpath='{.spec.taints[?(@.key=="dedicated")].effect}')"
  [ "$TAINT_VALUE" = "ops" ] || {
    echo "Node '$NODE' does not keep dedicated=ops taint"
    exit 1
  }
  [ "$TAINT_EFFECT" = "NoSchedule" ] || {
    echo "Node '$NODE' does not keep NoSchedule effect on dedicated taint"
    exit 1
  }
done <<EOF_NODES
$OPS_NODES
EOF_NODES

BAD_PODS="$(
  while IFS='|' read -r POD DELETION_TS PHASE NODE; do
    [ -n "$POD" ] || continue
    [ -z "$DELETION_TS" ] || continue
    [ "$PHASE" = "Running" ] || {
      echo "$POD phase=$PHASE"
      continue
    }
    [ -n "$NODE" ] || {
      echo "$POD node=<none>"
      continue
    }
    LABEL="$(kubectl get node "$NODE" -o jsonpath='{.metadata.labels.workload}')"
    [ "$LABEL" = "ops" ] || echo "$POD $NODE"
  done <<EOF_PODS
$(kubectl get pods -n "$NAMESPACE" -l app="$DEPLOYMENT" -o jsonpath='{range .items[*]}{.metadata.name}{"|"}{.metadata.deletionTimestamp}{"|"}{.status.phase}{"|"}{.spec.nodeName}{"\n"}{end}')
EOF_PODS
)"
[ -z "$BAD_PODS" ] || {
  echo "Some active Pods escaped the intended ops node pool:"
  echo "$BAD_PODS"
  exit 1
}

echo "Scheduling fix keeps the workload constrained to the intended ops node pool"
