#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="subpath-lab"
DEPLOYMENT="subpath-api"

CONFIGMAP_NAME="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.volumes[0].configMap.name}')"
ITEM_PATH="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.volumes[0].configMap.items[0].path}')"
MOUNT_PATH="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}')"
SUB_PATH="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].subPath}')"
READ_ONLY="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].readOnly}')"

[ "${CONFIGMAP_NAME}" = "app-config" ] || {
  echo "subpath-api must mount ConfigMap app-config"
  exit 1
}

[ "${ITEM_PATH}" = "config/app.conf" ] || {
  echo "subpath-api must use ConfigMap item path config/app.conf"
  exit 1
}

[ "${MOUNT_PATH}" = "/etc/app/app.conf" ] || {
  echo "subpath-api must mount the file at /etc/app/app.conf"
  exit 1
}

[ "${SUB_PATH}" = "config/app.conf" ] || {
  echo "subpath-api must use subPath config/app.conf"
  exit 1
}

[ "${READ_ONLY}" = "true" ] || {
  echo "subpath-api mount must stay readOnly"
  exit 1
}

echo "Deployment subpath-api uses the intended ConfigMap item path, subPath, mount path, and readOnly mount"
