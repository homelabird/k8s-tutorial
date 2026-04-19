#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="identity-lab"
DEPLOYMENT="metrics-api"

SERVICE_ACCOUNT="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.serviceAccountName}')"
AUTOMOUNT="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.automountServiceAccountToken}')"
TOKEN_PATH="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[0].serviceAccountToken.path}')"
TOKEN_AUDIENCE="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[0].serviceAccountToken.audience}')"
MOUNT_PATH="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}')"
READ_ONLY="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].readOnly}')"

[ "${SERVICE_ACCOUNT}" = "metrics-sa" ] || { echo "metrics-api must use ServiceAccount metrics-sa"; exit 1; }
[ "${AUTOMOUNT}" = "false" ] || { echo "metrics-api must set automountServiceAccountToken to false"; exit 1; }
[ "${TOKEN_PATH}" = "token" ] || { echo "The projected serviceAccountToken path must be token"; exit 1; }
[ "${TOKEN_AUDIENCE}" = "metrics-api" ] || { echo "The projected serviceAccountToken audience must be metrics-api"; exit 1; }
[ "${MOUNT_PATH}" = "/var/run/metrics" ] || { echo "The projected token volume must mount at /var/run/metrics"; exit 1; }
[ "${READ_ONLY}" = "true" ] || { echo "The projected token volume must stay readOnly"; exit 1; }

echo "Deployment metrics-api uses the intended ServiceAccount and projected token settings"
