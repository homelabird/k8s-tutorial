#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="envfrom-lab"
DEPLOYMENT="env-bundle"

CONTAINER_NAME="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].name}')"
IMAGE_REFERENCE="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].image}')"
CONFIGMAP_NAME="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].envFrom[0].configMapRef.name}')"
SECRET_NAME="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].envFrom[1].secretRef.name}')"
SECRET_PREFIX="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].envFrom[1].prefix}')"

[ "${CONTAINER_NAME}" = "api" ] || { echo "The container must remain named api"; exit 1; }
[ "${IMAGE_REFERENCE}" = "busybox:1.36" ] || { echo "The image must remain busybox:1.36"; exit 1; }
[ "${CONFIGMAP_NAME}" = "app-env" ] || { echo "The ConfigMap envFrom source must be app-env"; exit 1; }
[ "${SECRET_NAME}" = "app-secret" ] || { echo "The Secret envFrom source must be app-secret"; exit 1; }
[ "${SECRET_PREFIX}" = "SECRET_" ] || { echo "The Secret envFrom prefix must be SECRET_"; exit 1; }

echo "Deployment env-bundle uses the intended container name, image, envFrom sources, and Secret prefix"
