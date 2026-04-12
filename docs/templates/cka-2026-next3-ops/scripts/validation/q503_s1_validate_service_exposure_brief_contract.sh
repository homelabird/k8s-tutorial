#!/bin/bash
set -euo pipefail

NAMESPACE="service-debug-lab"
CONFIGMAP="service-exposure-brief"

kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" >/dev/null 2>&1 || {
  echo "ConfigMap $CONFIGMAP not found"
  exit 1
}

get_key() {
  kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" -o jsonpath="{.data.$1}"
}

[ "$(get_key serviceName)" = "echo-api" ] || { echo "serviceName must be echo-api"; exit 1; }
[ "$(get_key serviceType)" = "ClusterIP" ] || { echo "serviceType must be ClusterIP"; exit 1; }
[ "$(get_key selectorKey)" = "app" ] || { echo "selectorKey must be app"; exit 1; }
[ "$(get_key selectorValue)" = "echo-api" ] || { echo "selectorValue must be echo-api"; exit 1; }
[ "$(get_key servicePort)" = "8080" ] || { echo "servicePort must be 8080"; exit 1; }
[ "$(get_key targetPort)" = "8080" ] || { echo "targetPort must be 8080"; exit 1; }
[ "$(get_key endpointCheck)" = "kubectl get endpoints echo-api -n service-debug-lab -o wide" ] || { echo "endpointCheck is incorrect"; exit 1; }
[ "$(get_key selectorCheck)" = "kubectl get svc echo-api -n service-debug-lab -o jsonpath='{.spec.selector.app}'" ] || { echo "selectorCheck is incorrect"; exit 1; }
[ "$(get_key reachabilityCheck)" = "kubectl exec -n service-debug-lab net-debug -- wget -qO- http://echo-api:8080/healthz" ] || { echo "reachabilityCheck is incorrect"; exit 1; }

echo "service exposure brief contract is repaired"
