#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="service-debug-lab"

service_value() {
  kubectl get service echo-api -n "${NAMESPACE}" -o "jsonpath={.$1}"
}

[ "$(service_value spec.type)" = "ClusterIP" ] || { echo "echo-api must stay ClusterIP"; exit 1; }
[ "$(service_value spec.selector.app)" = "echo-api" ] || { echo "echo-api selector must be app=echo-api"; exit 1; }
[ "$(service_value spec.ports[0].port)" = "8080" ] || { echo "echo-api port must be 8080"; exit 1; }
[ "$(service_value spec.ports[0].targetPort)" = "8080" ] || { echo "echo-api targetPort must be 8080"; exit 1; }

echo "service exposure spec is repaired"
