#!/bin/bash
set -euo pipefail

NAMESPACE="triage-lab"
DEPLOYMENT="ops-api"

API_PORT="$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[?(@.name=="api")].ports[0].containerPort}')"
API_MEMORY_LIMIT="$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[?(@.name=="api")].resources.limits.memory}')"
PROBE_PORT="$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[?(@.name=="api")].livenessProbe.httpGet.port}')"
LOG_TARGET="$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[?(@.name=="log-agent")].env[?(@.name=="LOG_TARGET")].value}')"

[ "$API_PORT" = "80" ] || { echo "api containerPort must be 80"; exit 1; }
[ "$API_MEMORY_LIMIT" = "256Mi" ] || { echo "api memory limit must be 256Mi"; exit 1; }
[ "$PROBE_PORT" = "80" ] || { echo "api livenessProbe port must be 80"; exit 1; }
[ "$LOG_TARGET" = "/var/log/ops/app.log" ] || { echo "log-agent LOG_TARGET must be /var/log/ops/app.log"; exit 1; }

echo "Deployment contract is repaired"
