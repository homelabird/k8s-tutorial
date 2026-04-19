#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="securitycontext-lab"
DEPLOYMENT="secure-api"

RUN_AS_USER="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.securityContext.runAsUser}')"
FS_GROUP="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.securityContext.fsGroup}')"
SECCOMP="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].securityContext.seccompProfile.type}')"
ALLOW_PRIV_ESC="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].securityContext.allowPrivilegeEscalation}')"
CAP_DROP="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].securityContext.capabilities.drop[0]}')"
MOUNT_PATH="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}')"

[ "${RUN_AS_USER}" = "1000" ] || { echo "Pod securityContext must use runAsUser 1000"; exit 1; }
[ "${FS_GROUP}" = "2000" ] || { echo "Pod securityContext must use fsGroup 2000"; exit 1; }
[ "${SECCOMP}" = "RuntimeDefault" ] || { echo "Container seccompProfile must be RuntimeDefault"; exit 1; }
[ "${ALLOW_PRIV_ESC}" = "false" ] || { echo "Container must set allowPrivilegeEscalation to false"; exit 1; }
[ "${CAP_DROP}" = "ALL" ] || { echo "Container must drop capability ALL"; exit 1; }
[ "${MOUNT_PATH}" = "/data" ] || { echo "The data volume must stay mounted at /data"; exit 1; }

echo "Deployment secure-api uses the intended pod and container securityContext settings"
