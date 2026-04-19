#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="stateful-lab"
SERVICE="web-svc"
STATEFULSET="web"

CLUSTER_IP="$(kubectl get service "${SERVICE}" -n "${NAMESPACE}" -o jsonpath='{.spec.clusterIP}')"
SELECTOR_APP="$(kubectl get service "${SERVICE}" -n "${NAMESPACE}" -o jsonpath='{.spec.selector.app}')"
SERVICE_NAME="$(kubectl get statefulset "${STATEFULSET}" -n "${NAMESPACE}" -o jsonpath='{.spec.serviceName}')"
REPLICAS="$(kubectl get statefulset "${STATEFULSET}" -n "${NAMESPACE}" -o jsonpath='{.spec.replicas}')"

[ "${CLUSTER_IP}" = "None" ] || { echo "web-svc must stay headless"; exit 1; }
[ "${SELECTOR_APP}" = "web" ] || { echo "web-svc must select app=web"; exit 1; }
[ "${SERVICE_NAME}" = "web-svc" ] || { echo "StatefulSet web must keep serviceName web-svc"; exit 1; }
[ "${REPLICAS}" = "2" ] || { echo "StatefulSet web must keep 2 replicas"; exit 1; }

echo "StatefulSet web and headless Service web-svc use the intended stable identity contract"
