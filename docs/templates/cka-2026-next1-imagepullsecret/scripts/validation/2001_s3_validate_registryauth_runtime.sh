#!/usr/bin/env bash
set -euo pipefail

POD_SERVICE_ACCOUNT="$(kubectl get pods -n registry-auth-lab -l app=private-api -o jsonpath='{.items[0].spec.serviceAccountName}')"
POD_IMAGE_PULL_SECRET="$(kubectl get pods -n registry-auth-lab -l app=private-api -o jsonpath='{.items[0].spec.imagePullSecrets[0].name}')"

[ "${POD_SERVICE_ACCOUNT}" = "puller" ] || { echo "The running Pod must use ServiceAccount puller"; exit 1; }
[ "${POD_IMAGE_PULL_SECRET}" = "regcred" ] || { echo "The running Pod must use imagePullSecret regcred"; exit 1; }

echo "The running Pod uses ServiceAccount puller and imagePullSecret regcred"
