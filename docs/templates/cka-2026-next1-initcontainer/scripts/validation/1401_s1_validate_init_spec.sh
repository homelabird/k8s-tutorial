#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="init-lab"
DEPLOYMENT="report-api"

INIT_NAME="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.initContainers[0].name}')"
INIT_COMMAND="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.initContainers[0].command[2]}')"
INIT_VOLUME="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.initContainers[0].volumeMounts[0].name}')"
INIT_MOUNT="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.initContainers[0].volumeMounts[0].mountPath}')"
APP_VOLUME="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].name}')"
APP_MOUNT="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}')"

[ "${INIT_NAME}" = "bootstrap" ] || { echo "The init container must remain named bootstrap"; exit 1; }
[ "${INIT_COMMAND}" = "mkdir -p /work && echo ready=1 > /work/report.txt" ] || {
  echo "The init container must write ready=1 to /work/report.txt"
  exit 1
}
[ "${INIT_VOLUME}" = "shared-data" ] || { echo "The init container must use volume shared-data"; exit 1; }
[ "${INIT_MOUNT}" = "/work" ] || { echo "The init container must mount the shared volume at /work"; exit 1; }
[ "${APP_VOLUME}" = "shared-data" ] || { echo "The app container must use volume shared-data"; exit 1; }
[ "${APP_MOUNT}" = "/work" ] || { echo "The app container must mount the shared volume at /work"; exit 1; }

echo "Deployment report-api uses the intended shared volume, mount paths, and init command"
