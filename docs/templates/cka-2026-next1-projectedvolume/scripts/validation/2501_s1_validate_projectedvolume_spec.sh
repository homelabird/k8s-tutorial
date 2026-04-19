#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="projectedvolume-lab"
DEPLOYMENT="bundle-api"

CONFIGMAP_NAME="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[0].configMap.name}')"
CONFIGMAP_PATH="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[0].configMap.items[0].path}')"
SECRET_NAME="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[1].secret.name}')"
SECRET_PATH="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[1].secret.items[0].path}')"
MOUNT_PATH="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}')"
READ_ONLY="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].readOnly}')"

[ "${CONFIGMAP_NAME}" = "bundle-config" ] || { echo "bundle-api must project ConfigMap bundle-config"; exit 1; }
[ "${CONFIGMAP_PATH}" = "config/app.conf" ] || { echo "The ConfigMap item path must be config/app.conf"; exit 1; }
[ "${SECRET_NAME}" = "bundle-secret" ] || { echo "bundle-api must project Secret bundle-secret"; exit 1; }
[ "${SECRET_PATH}" = "secret/token" ] || { echo "The Secret item path must be secret/token"; exit 1; }
[ "${MOUNT_PATH}" = "/etc/bundle" ] || { echo "The projected volume must mount at /etc/bundle"; exit 1; }
[ "${READ_ONLY}" = "true" ] || { echo "The projected volume must be readOnly"; exit 1; }

echo "Deployment bundle-api uses the intended projected source names, item paths, and mount settings"
