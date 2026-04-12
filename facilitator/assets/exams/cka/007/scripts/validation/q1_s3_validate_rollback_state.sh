#!/bin/bash
set -euo pipefail

NAMESPACE="rollout-lab"
DEPLOYMENT="web-app"
ORIGINAL_IMAGE="nginx:1.25.3"
UPDATED_IMAGE="nginx:1.25.5"

kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" >/dev/null 2>&1 || {
  echo "Deployment '$DEPLOYMENT' not found in namespace '$NAMESPACE'"
  exit 1
}

kubectl rollout status deployment "$DEPLOYMENT" -n "$NAMESPACE" --timeout=180s >/dev/null 2>&1 || {
  echo "Deployment '$DEPLOYMENT' is not healthy after rollback"
  exit 1
}

CURRENT_IMAGE="$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].image}')"
[ "$CURRENT_IMAGE" = "$ORIGINAL_IMAGE" ] || {
  echo "Deployment was not rolled back to the original image. Got '$CURRENT_IMAGE'"
  exit 1
}

BAD_PODS="$(kubectl get pods -n "$NAMESPACE" -l app="$DEPLOYMENT" -o jsonpath='{range .items[*]}{.metadata.name} {.spec.containers[0].image}{"\n"}{end}' | grep "$UPDATED_IMAGE" || true)"
[ -z "$BAD_PODS" ] || {
  echo "Some Pods are still running the updated image:"
  echo "$BAD_PODS"
  exit 1
}

AVAILABLE="$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.status.availableReplicas}')"
[ -n "$AVAILABLE" ] && [ "$AVAILABLE" -ge 1 ] 2>/dev/null || {
  echo "Deployment has no available replicas after rollback"
  exit 1
}

echo "Deployment was rolled back and is healthy on the original image"
