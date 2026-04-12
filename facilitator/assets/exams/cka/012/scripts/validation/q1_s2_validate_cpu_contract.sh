#!/bin/bash
set -euo pipefail

NAMESPACE="autoscale-lab"
DEPLOYMENT="worker-api"
HPA="worker-api-hpa"

METRIC_NAME="$(kubectl get hpa "$HPA" -n "$NAMESPACE" -o jsonpath='{.spec.metrics[0].resource.name}')"
TARGET_TYPE="$(kubectl get hpa "$HPA" -n "$NAMESPACE" -o jsonpath='{.spec.metrics[0].resource.target.type}')"
TARGET_UTILIZATION="$(kubectl get hpa "$HPA" -n "$NAMESPACE" -o jsonpath='{.spec.metrics[0].resource.target.averageUtilization}')"
CPU_REQUEST="$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[?(@.name=="api")].resources.requests.cpu}')"

[ "$METRIC_NAME" = "cpu" ] || { echo "HPA must scale on cpu"; exit 1; }
[ "$TARGET_TYPE" = "Utilization" ] || { echo "HPA target type must be Utilization"; exit 1; }
[ "$TARGET_UTILIZATION" = "60" ] || { echo "CPU utilization target must be 60"; exit 1; }
[ "$CPU_REQUEST" = "200m" ] || { echo "Deployment api container must request 200m CPU"; exit 1; }

echo "CPU autoscaling target and workload CPU request are configured correctly"
