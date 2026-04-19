#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="registry-auth-lab"
DEPLOYMENT="private-api"

SERVICE_ACCOUNT="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.serviceAccountName}')"
IMAGE_PULL_SECRET="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.imagePullSecrets[0].name}')"
IMAGE_REFERENCE="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].image}')"
SECRET_TYPE="$(kubectl get secret regcred -n "${NAMESPACE}" -o jsonpath='{.type}')"
SERVICE_ACCOUNT_SECRET="$(kubectl get serviceaccount puller -n "${NAMESPACE}" -o jsonpath='{.imagePullSecrets[0].name}')"

[ "${SERVICE_ACCOUNT}" = "puller" ] || { echo "private-api must use ServiceAccount puller"; exit 1; }
[ "${IMAGE_PULL_SECRET}" = "regcred" ] || { echo "private-api must use imagePullSecret regcred"; exit 1; }
[ "${IMAGE_REFERENCE}" = "busybox:1.36" ] || { echo "private-api must keep image busybox:1.36"; exit 1; }
[ "${SECRET_TYPE}" = "kubernetes.io/dockerconfigjson" ] || { echo "regcred must keep type kubernetes.io/dockerconfigjson"; exit 1; }
[ "${SERVICE_ACCOUNT_SECRET}" = "regcred" ] || { echo "ServiceAccount puller must reference regcred"; exit 1; }

echo "Deployment private-api uses the intended ServiceAccount, imagePullSecret, image reference, and existing Secret type"
