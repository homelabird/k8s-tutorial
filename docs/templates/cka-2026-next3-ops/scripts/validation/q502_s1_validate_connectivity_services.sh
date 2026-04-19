#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="connectivity-lab"

service_value() {
  kubectl get service echo-api -n "${NAMESPACE}" -o "jsonpath={.$1}"
}

headless_value() {
  kubectl get service echo-api-headless -n "${NAMESPACE}" -o "jsonpath={.$1}"
}

stateful_value() {
  kubectl get statefulset echo-api -n "${NAMESPACE}" -o "jsonpath={.$1}"
}

[ "$(service_value spec.type)" = "ClusterIP" ] || { echo "echo-api must stay ClusterIP"; exit 1; }
[ "$(service_value spec.selector.app)" = "echo-api" ] || { echo "echo-api selector must be app=echo-api"; exit 1; }
[ "$(service_value spec.ports[0].port)" = "8080" ] || { echo "echo-api port must be 8080"; exit 1; }
[ "$(service_value spec.ports[0].targetPort)" = "8080" ] || { echo "echo-api targetPort must be 8080"; exit 1; }
[ "$(headless_value spec.clusterIP)" = "None" ] || { echo "echo-api-headless must stay headless"; exit 1; }
[ "$(headless_value spec.selector.app)" = "echo-api" ] || { echo "echo-api-headless selector must be app=echo-api"; exit 1; }
[ "$(stateful_value spec.serviceName)" = "echo-api-headless" ] || { echo "StatefulSet serviceName must be echo-api-headless"; exit 1; }
[ "$(stateful_value spec.replicas)" = "1" ] || { echo "StatefulSet replicas must be 1"; exit 1; }

echo "connectivity services are wired correctly"
