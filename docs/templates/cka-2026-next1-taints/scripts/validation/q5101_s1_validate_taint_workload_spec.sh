#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="taints-lab"
DEPLOYMENT="taint-api"

NODE_SELECTOR="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.nodeSelector.workload}')"
TOLERATION_KEY="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.tolerations[?(@.key=="dedicated")].key}')"
TOLERATION_VALUE="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.tolerations[?(@.key=="dedicated")].value}')"
TOLERATION_EFFECT="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.tolerations[?(@.key=="dedicated")].effect}')"
TOLERATION_SECONDS="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.tolerations[?(@.key=="dedicated")].tolerationSeconds}')"

[ "${NODE_SELECTOR}" = "ops" ] || exit 1
[ "${TOLERATION_KEY}" = "dedicated" ] || exit 1
[ "${TOLERATION_VALUE}" = "ops" ] || exit 1
[ "${TOLERATION_EFFECT}" = "NoExecute" ] || exit 1
[ "${TOLERATION_SECONDS}" = "60" ] || exit 1

echo "Deployment includes the required NoExecute toleration and node selection rules"
