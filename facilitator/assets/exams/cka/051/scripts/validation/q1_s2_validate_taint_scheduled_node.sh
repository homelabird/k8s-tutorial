#!/usr/bin/env bash
set -euo pipefail

kubectl rollout status deployment/taint-api -n taints-lab --timeout=180s >/dev/null || {
  echo "Deployment taint-api did not become Available"
  exit 1
}

POD_NAME="$(kubectl get pods -n taints-lab -l app=taint-api --field-selector=status.phase=Running --sort-by=.metadata.creationTimestamp -o name | tail -n 1 | cut -d/ -f2)"
[ -n "${POD_NAME}" ] || exit 1
NODE_NAME="$(kubectl get pod "${POD_NAME}" -n taints-lab -o jsonpath='{.spec.nodeName}')"
NODE_LABEL="$(kubectl get node "${NODE_NAME}" -o jsonpath='{.metadata.labels.workload}')"

[ "${NODE_LABEL}" = "ops" ] || {
  echo "taint-api Pod is not running on a workload=ops node"
  exit 1
}

echo "taint-api Pod is Running on a node labeled workload=ops"
