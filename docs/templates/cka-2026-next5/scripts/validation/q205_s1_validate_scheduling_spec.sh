#!/bin/bash
set -euo pipefail

NAMESPACE="scheduling-lab"
DEPLOYMENT="metrics-agent"

kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" >/dev/null 2>&1 || {
  echo "Deployment '$DEPLOYMENT' not found in namespace '$NAMESPACE'"
  exit 1
}

NODE_SELECTOR="$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.nodeSelector.workload}')"
TOLERATION_KEY="$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.tolerations[?(@.key=="dedicated")].key}')"
TOLERATION_VALUE="$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.tolerations[?(@.key=="dedicated")].value}')"
TOLERATION_EFFECT="$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.tolerations[?(@.key=="dedicated")].effect}')"

[ "$NODE_SELECTOR" = "ops" ] || {
  echo "Deployment must target workload=ops, got '$NODE_SELECTOR'"
  exit 1
}

[ "$TOLERATION_KEY" = "dedicated" ] || {
  echo "Deployment is missing toleration key 'dedicated'"
  exit 1
}

[ "$TOLERATION_VALUE" = "ops" ] || {
  echo "Deployment toleration value must be 'ops', got '$TOLERATION_VALUE'"
  exit 1
}

[ "$TOLERATION_EFFECT" = "NoSchedule" ] || {
  echo "Deployment toleration effect must be 'NoSchedule', got '$TOLERATION_EFFECT'"
  exit 1
}

echo "Deployment includes the required toleration and node selection rules"
