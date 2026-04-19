#!/usr/bin/env bash
set -euo pipefail

kubectl rollout status deployment/lifecycle-api -n lifecycle-lab --timeout=180s >/dev/null || {
  echo "Deployment lifecycle-api did not become Available"
  exit 1
}

AVAILABLE="$(kubectl get deployment lifecycle-api -n lifecycle-lab -o jsonpath='{.status.availableReplicas}')"
[ "${AVAILABLE}" = "1" ] || {
  echo "Deployment lifecycle-api is not reporting one available replica"
  exit 1
}

echo "Deployment lifecycle-api becomes Available on the updated Pod template"
