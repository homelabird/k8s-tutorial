#!/usr/bin/env bash
set -euo pipefail

CLAIM_NAME="$(kubectl get deployment rwop-reader -n rwop-lab -o jsonpath='{.spec.template.spec.volumes[0].persistentVolumeClaim.claimName}')"
MOUNT_PATH="$(kubectl get deployment rwop-reader -n rwop-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}')"

[ "${CLAIM_NAME}" = "data-claim" ] || {
  echo "rwop-reader must use PVC data-claim"
  exit 1
}

[ "${MOUNT_PATH}" = "/data/app" ] || {
  echo "rwop-reader must mount the claim at /data/app"
  exit 1
}

kubectl rollout status deployment/rwop-reader -n rwop-lab --timeout=180s >/dev/null || {
  echo "Deployment rwop-reader did not become Available"
  exit 1
}

echo "Deployment rwop-reader uses data-claim at /data/app and becomes Available"
