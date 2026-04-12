#!/bin/bash
set -euo pipefail

NAMESPACE="rollout-lab"
DEPLOYMENT="web-app"

kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" >/dev/null 2>&1 || {
  echo "Deployment '$DEPLOYMENT' not found in namespace '$NAMESPACE'"
  exit 1
}

STRATEGY="$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.strategy.type}')"
MAX_UNAVAILABLE="$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.strategy.rollingUpdate.maxUnavailable}')"
MAX_SURGE="$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.strategy.rollingUpdate.maxSurge}')"
AVAILABLE="$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.status.availableReplicas}')"

[ "$STRATEGY" = "RollingUpdate" ] || {
  echo "Deployment strategy must be RollingUpdate, got '$STRATEGY'"
  exit 1
}

[ "$MAX_UNAVAILABLE" = "1" ] || {
  echo "maxUnavailable must be 1, got '$MAX_UNAVAILABLE'"
  exit 1
}

[ "$MAX_SURGE" = "1" ] || {
  echo "maxSurge must be 1, got '$MAX_SURGE'"
  exit 1
}

[ -n "$AVAILABLE" ] && [ "$AVAILABLE" -ge 1 ] 2>/dev/null || {
  echo "Deployment is not available"
  exit 1
}

echo "Deployment strategy is configured for a controlled rolling update"
