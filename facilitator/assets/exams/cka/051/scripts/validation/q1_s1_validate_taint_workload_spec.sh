#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="taints-lab"
DEPLOYMENT="taint-api"

NODE_SELECTOR="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.nodeSelector.workload}')"
TOLERATION_KEY="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.tolerations[?(@.key=="dedicated")].key}')"
TOLERATION_VALUE="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.tolerations[?(@.key=="dedicated")].value}')"
TOLERATION_EFFECT="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.tolerations[?(@.key=="dedicated")].effect}')"
TOLERATION_SECONDS="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.tolerations[?(@.key=="dedicated")].tolerationSeconds}')"

[ "${NODE_SELECTOR}" = "ops" ] || {
  echo "Deployment must target workload=ops"
  exit 1
}

[ "${TOLERATION_KEY}" = "dedicated" ] || {
  echo "Deployment is missing toleration key dedicated"
  exit 1
}

[ "${TOLERATION_VALUE}" = "ops" ] || {
  echo "Deployment toleration value must be ops"
  exit 1
}

[ "${TOLERATION_EFFECT}" = "NoExecute" ] || {
  echo "Deployment toleration effect must be NoExecute"
  exit 1
}

[ "${TOLERATION_SECONDS}" = "60" ] || {
  echo "Deployment tolerationSeconds must be 60"
  exit 1
}

echo "Deployment taint-api includes the required NoExecute toleration and node selection rules"
