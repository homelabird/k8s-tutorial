#!/usr/bin/env bash
set -euo pipefail

PVC_VOLUME="$(kubectl get pvc analytics-data -n pv-resize-lab -o jsonpath='{.spec.volumeName}')"
PVC_REQUEST="$(kubectl get pvc analytics-data -n pv-resize-lab -o jsonpath='{.spec.resources.requests.storage}')"
PVC_SC="$(kubectl get pvc analytics-data -n pv-resize-lab -o jsonpath='{.spec.storageClassName}')"
ALLOW_EXPANSION="$(kubectl get storageclass expandable-reports -o jsonpath='{.allowVolumeExpansion}')"
CLAIM_NAME="$(kubectl get deployment analytics-api -n pv-resize-lab -o jsonpath='{.spec.template.spec.volumes[0].persistentVolumeClaim.claimName}')"
MOUNT_PATH="$(kubectl get deployment analytics-api -n pv-resize-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}')"

[ "${PVC_VOLUME}" = "analytics-pv" ] || { echo "analytics-data must stay bound to analytics-pv"; exit 1; }
[ "${PVC_REQUEST}" = "2Gi" ] || { echo "analytics-data must request 2Gi"; exit 1; }
[ "${PVC_SC}" = "expandable-reports" ] || { echo "analytics-data must keep storageClassName expandable-reports"; exit 1; }
[ "${ALLOW_EXPANSION}" = "true" ] || { echo "expandable-reports must keep allowVolumeExpansion true"; exit 1; }
[ "${CLAIM_NAME}" = "analytics-data" ] || { echo "analytics-api must use PVC analytics-data"; exit 1; }
[ "${MOUNT_PATH}" = "/var/lib/analytics" ] || { echo "analytics-api must mount storage at /var/lib/analytics"; exit 1; }

echo "The resize-capable PVC contract stays intact and analytics-api uses the intended claim, request size, and mount path"
