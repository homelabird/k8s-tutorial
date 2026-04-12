#!/bin/bash
set -euo pipefail

TARGET_NODE="$(kubectl get nodes -l maintenance-lab=target -o jsonpath='{.items[0].metadata.name}')"
[ -n "$TARGET_NODE" ] || {
  echo "No node labeled maintenance-lab=target found"
  exit 1
}

NODE_COUNT="$(kubectl get nodes -l maintenance-lab=target --no-headers 2>/dev/null | wc -l | tr -d '[:space:]')"
[ "$NODE_COUNT" = "1" ] || {
  echo "Expected exactly one maintenance target node"
  exit 1
}

UNSCHEDULABLE="$(kubectl get node "$TARGET_NODE" -o jsonpath='{.spec.unschedulable}' 2>/dev/null || true)"
READY_STATUS="$(kubectl get node "$TARGET_NODE" -o jsonpath='{range .status.conditions[?(@.type=="Ready")]}{.status}{end}')"

[ "$UNSCHEDULABLE" != "true" ] || { echo "Target node is still unschedulable"; exit 1; }
[ "$READY_STATUS" = "True" ] || { echo "Target node is not Ready"; exit 1; }

echo "The maintenance target node is Ready and schedulable again"
