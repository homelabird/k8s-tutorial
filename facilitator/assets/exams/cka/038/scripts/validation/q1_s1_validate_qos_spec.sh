#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="qos-lab"
DEPLOYMENT="reporting-api"

REQUEST_CPU="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}')"
REQUEST_MEMORY="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}')"
LIMIT_CPU="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}')"
LIMIT_MEMORY="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}')"

[ "${REQUEST_CPU}" = "250m" ] || { echo "requests.cpu must be 250m"; exit 1; }
[ "${REQUEST_MEMORY}" = "256Mi" ] || { echo "requests.memory must be 256Mi"; exit 1; }
[ "${LIMIT_CPU}" = "250m" ] || { echo "limits.cpu must be 250m"; exit 1; }
[ "${LIMIT_MEMORY}" = "256Mi" ] || { echo "limits.memory must be 256Mi"; exit 1; }

echo "Deployment reporting-api uses the intended requests and limits"
