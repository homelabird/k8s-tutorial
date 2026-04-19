#!/usr/bin/env bash
set -euo pipefail

PHASE="$(kubectl get pvc data-claim -n rwop-lab -o jsonpath='{.status.phase}')"
ACCESS_MODE="$(kubectl get pvc data-claim -n rwop-lab -o jsonpath='{.spec.accessModes[0]}')"
VOLUME_NAME="$(kubectl get pvc data-claim -n rwop-lab -o jsonpath='{.spec.volumeName}')"

[ "${PHASE}" = "Bound" ] || {
  echo "PVC data-claim is not Bound"
  exit 1
}

[ "${ACCESS_MODE}" = "ReadWriteOncePod" ] || {
  echo "PVC data-claim must keep ReadWriteOncePod"
  exit 1
}

[ "${VOLUME_NAME}" = "rwop-pv" ] || {
  echo "PVC data-claim is not bound to rwop-pv"
  exit 1
}

echo "PVC data-claim stays bound and keeps the intended ReadWriteOncePod access mode"
