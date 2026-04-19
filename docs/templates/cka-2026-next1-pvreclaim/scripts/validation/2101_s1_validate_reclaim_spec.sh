#!/usr/bin/env bash
set -euo pipefail

PVC_VOLUME="$(kubectl get pvc reports-data -n pv-reclaim-lab -o jsonpath='{.spec.volumeName}')"
PVC_SC="$(kubectl get pvc reports-data -n pv-reclaim-lab -o jsonpath='{.spec.storageClassName}')"
RECLAIM_POLICY="$(kubectl get pv reports-pv -o jsonpath='{.spec.persistentVolumeReclaimPolicy}')"
CLAIM_REF="$(kubectl get pv reports-pv -o jsonpath='{.spec.claimRef.namespace}/{.spec.claimRef.name}')"
CLAIM_NAME="$(kubectl get deployment reports-db -n pv-reclaim-lab -o jsonpath='{.spec.template.spec.volumes[0].persistentVolumeClaim.claimName}')"
MOUNT_PATH="$(kubectl get deployment reports-db -n pv-reclaim-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}')"

[ "${PVC_VOLUME}" = "reports-pv" ] || { echo "reports-data must stay bound to reports-pv"; exit 1; }
[ "${PVC_SC}" = "manual-reports" ] || { echo "reports-data must keep storageClassName manual-reports"; exit 1; }
[ "${RECLAIM_POLICY}" = "Retain" ] || { echo "reports-pv must keep reclaim policy Retain"; exit 1; }
[ "${CLAIM_REF}" = "pv-reclaim-lab/reports-data" ] || { echo "reports-pv must keep claimRef pv-reclaim-lab/reports-data"; exit 1; }
[ "${CLAIM_NAME}" = "reports-data" ] || { echo "reports-db must use PVC reports-data"; exit 1; }
[ "${MOUNT_PATH}" = "/var/lib/reporting" ] || { echo "reports-db must mount storage at /var/lib/reporting"; exit 1; }

echo "The bound PVC/PV contract stays intact and Deployment reports-db uses the intended claim and mount path"
