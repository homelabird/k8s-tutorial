#!/bin/bash
set -euo pipefail

NAMESPACE="probe-lab"
CONFIGMAP="probe-diagnostics-brief"

kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" >/dev/null 2>&1 || {
  echo "ConfigMap $CONFIGMAP not found"
  exit 1
}

get_key() {
  kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" -o jsonpath="{.data.$1}"
}

[ "$(get_key targetDeployment)" = "health-api" ] || { echo "targetDeployment must be health-api"; exit 1; }
[ "$(get_key deploymentInventory)" = "kubectl get deployment health-api -n probe-lab -o wide" ] || { echo "deploymentInventory is incorrect"; exit 1; }
[ "$(get_key startupProbeCheck)" = "kubectl get deployment health-api -n probe-lab -o jsonpath='{.spec.template.spec.containers[0].startupProbe.httpGet.path}'" ] || { echo "startupProbeCheck is incorrect"; exit 1; }
[ "$(get_key livenessProbeCheck)" = "kubectl get deployment health-api -n probe-lab -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.httpGet.path}'" ] || { echo "livenessProbeCheck is incorrect"; exit 1; }
[ "$(get_key readinessProbeCheck)" = "kubectl get deployment health-api -n probe-lab -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.path}'" ] || { echo "readinessProbeCheck is incorrect"; exit 1; }
[ "$(get_key portCheck)" = "kubectl get deployment health-api -n probe-lab -o jsonpath='{.spec.template.spec.containers[0].ports[0].containerPort}'" ] || { echo "portCheck is incorrect"; exit 1; }
[ "$(get_key eventCheck)" = "kubectl get events -n probe-lab --sort-by=.lastTimestamp" ] || { echo "eventCheck is incorrect"; exit 1; }
[ "$(get_key safeManifestNote)" = "confirm startup, liveness, readiness probe paths and thresholds before changing the Deployment manifest" ] || { echo "safeManifestNote is incorrect"; exit 1; }

echo "probe diagnostics brief contract is repaired"
