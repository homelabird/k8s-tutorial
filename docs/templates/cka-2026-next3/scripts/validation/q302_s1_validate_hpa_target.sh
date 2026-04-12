#!/bin/bash
set -euo pipefail

NAMESPACE="autoscale-lab"
HPA="worker-api-hpa"

TARGET_KIND="$(kubectl get hpa "$HPA" -n "$NAMESPACE" -o jsonpath='{.spec.scaleTargetRef.kind}')"
TARGET_NAME="$(kubectl get hpa "$HPA" -n "$NAMESPACE" -o jsonpath='{.spec.scaleTargetRef.name}')"
MIN_REPLICAS="$(kubectl get hpa "$HPA" -n "$NAMESPACE" -o jsonpath='{.spec.minReplicas}')"
MAX_REPLICAS="$(kubectl get hpa "$HPA" -n "$NAMESPACE" -o jsonpath='{.spec.maxReplicas}')"

[ "$TARGET_KIND" = "Deployment" ] || { echo "HPA must target a Deployment"; exit 1; }
[ "$TARGET_NAME" = "worker-api" ] || { echo "HPA must target Deployment worker-api"; exit 1; }
[ "$MIN_REPLICAS" = "2" ] || { echo "minReplicas must be 2"; exit 1; }
[ "$MAX_REPLICAS" = "5" ] || { echo "maxReplicas must be 5"; exit 1; }

echo "HPA target and replica bounds are correct"
