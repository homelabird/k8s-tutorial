#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="downwardapi-lab"
DEPLOYMENT="meta-api"

ENV0_NAME="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].env[0].name}')"
ENV0_FIELD="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].env[0].valueFrom.fieldRef.fieldPath}')"
ENV1_NAME="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].env[1].name}')"
ENV1_FIELD="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].env[1].valueFrom.fieldRef.fieldPath}')"

[ "${ENV0_NAME}" = "POD_NAME" ] || {
  echo "First env var must be POD_NAME"
  exit 1
}

[ "${ENV0_FIELD}" = "metadata.name" ] || {
  echo "POD_NAME must use metadata.name"
  exit 1
}

[ "${ENV1_NAME}" = "POD_NAMESPACE" ] || {
  echo "Second env var must be POD_NAMESPACE"
  exit 1
}

[ "${ENV1_FIELD}" = "metadata.namespace" ] || {
  echo "POD_NAMESPACE must use metadata.namespace"
  exit 1
}

echo "Deployment meta-api uses the intended Downward API env names and fieldRef paths"
