#!/bin/bash
set -euo pipefail

NAMESPACE="connectivity-lab"
CONFIGMAP="connectivity-brief"

kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" >/dev/null 2>&1 || {
  echo "ConfigMap $CONFIGMAP not found"
  exit 1
}

get_key() {
  kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" -o jsonpath="{.data.$1}"
}

[ "$(get_key debugPod)" = "net-debug" ] || { echo "debugPod must be net-debug"; exit 1; }
[ "$(get_key serviceName)" = "echo-api" ] || { echo "serviceName must be echo-api"; exit 1; }
[ "$(get_key servicePort)" = "8080" ] || { echo "servicePort must be 8080"; exit 1; }
[ "$(get_key headlessServiceName)" = "echo-api-headless" ] || { echo "headlessServiceName must be echo-api-headless"; exit 1; }
[ "$(get_key podDnsName)" = "echo-api-0.echo-api-headless.connectivity-lab.svc.cluster.local" ] || { echo "podDnsName is incorrect"; exit 1; }
[ "$(get_key serviceProbe)" = "kubectl exec -n connectivity-lab net-debug -- wget -qO- http://echo-api:8080/healthz" ] || { echo "serviceProbe is incorrect"; exit 1; }
[ "$(get_key podProbe)" = "kubectl exec -n connectivity-lab net-debug -- wget -qO- http://echo-api-0.echo-api-headless.connectivity-lab.svc.cluster.local:8080/healthz" ] || { echo "podProbe is incorrect"; exit 1; }
[ "$(get_key dnsProbe)" = "kubectl exec -n connectivity-lab net-debug -- nslookup echo-api.connectivity-lab.svc.cluster.local" ] || { echo "dnsProbe is incorrect"; exit 1; }

echo "connectivity brief contract is repaired"
