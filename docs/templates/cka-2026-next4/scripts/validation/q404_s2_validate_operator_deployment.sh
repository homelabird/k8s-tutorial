#!/bin/bash
set -euo pipefail

NAMESPACE="operator-lab"
DEPLOYMENT="widget-operator"

IMAGE="$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[?(@.name=="manager")].image}')"
REPLICAS="$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')"
READY_REPLICAS="$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')"
COMMAND="$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o json | jq -r '.spec.template.spec.containers[] | select(.name=="manager") | .command | join(" ")')"

[ "$IMAGE" = "busybox:1.36.1" ] || { echo "widget-operator image must be busybox:1.36.1"; exit 1; }
[ "$REPLICAS" = "1" ] || { echo "widget-operator replicas must be 1"; exit 1; }
[ "${READY_REPLICAS:-0}" = "1" ] || { echo "widget-operator must have one ready replica"; exit 1; }
printf '%s' "$COMMAND" | grep -Fq 'sleep 3600' || { echo "widget-operator command must sleep 3600"; exit 1; }

echo "Operator deployment contract is repaired"
