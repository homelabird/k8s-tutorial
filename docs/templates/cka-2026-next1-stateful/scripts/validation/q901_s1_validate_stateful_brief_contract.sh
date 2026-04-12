#!/bin/bash
set -euo pipefail

NAMESPACE="stateful-lab"
CONFIGMAP="stateful-identity-brief"

kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" >/dev/null 2>&1 || {
  echo "ConfigMap $CONFIGMAP not found"
  exit 1
}

get_key() {
  kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" -o jsonpath="{.data.$1}"
}

[ "$(get_key targetStatefulSet)" = "web" ] || { echo "targetStatefulSet must be web"; exit 1; }
[ "$(get_key headlessService)" = "web-svc" ] || { echo "headlessService must be web-svc"; exit 1; }
[ "$(get_key statefulSetInventory)" = "kubectl get statefulset web -n stateful-lab -o wide" ] || { echo "statefulSetInventory is incorrect"; exit 1; }
[ "$(get_key serviceInspection)" = "kubectl get svc web-svc -n stateful-lab -o yaml" ] || { echo "serviceInspection is incorrect"; exit 1; }
[ "$(get_key podInventory)" = "kubectl get pods -n stateful-lab -l app=web -o wide" ] || { echo "podInventory is incorrect"; exit 1; }
[ "$(get_key ordinalDnsCheck)" = "kubectl exec -n stateful-lab dns-debug -- nslookup web-0.web-svc.stateful-lab.svc.cluster.local" ] || { echo "ordinalDnsCheck is incorrect"; exit 1; }
[ "$(get_key pvcInventory)" = "kubectl get pvc -n stateful-lab" ] || { echo "pvcInventory is incorrect"; exit 1; }
[ "$(get_key safeManifestNote)" = "confirm serviceName: web-svc and stable pod ordinals before changing manifests" ] || { echo "safeManifestNote is incorrect"; exit 1; }

echo "stateful identity brief contract is repaired"
