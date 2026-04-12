#!/bin/bash
set -euo pipefail

NAMESPACE="gateway-lab"
OUTPUT_FILE="/tmp/exam/q401/app-routes.yaml"

for deployment in app1 app2; do
  READY="$(kubectl get deployment "$deployment" -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || true)"
  [ "${READY:-0}" -ge 1 ] || { echo "Deployment $deployment must have a ready replica"; exit 1; }
done

for service in app1-svc app2-svc; do
  PORT="$(kubectl get service "$service" -n "$NAMESPACE" -o jsonpath='{.spec.ports[0].port}' 2>/dev/null || true)"
  ENDPOINTS="$(kubectl get endpoints "$service" -n "$NAMESPACE" -o jsonpath='{.subsets[0].addresses[0].ip}' 2>/dev/null || true)"
  [ "$PORT" = "8080" ] || { echo "Service $service must expose port 8080"; exit 1; }
  [ -n "$ENDPOINTS" ] || { echo "Service $service must have ready endpoints"; exit 1; }
done

[ -f "$OUTPUT_FILE" ] || { echo "Expected repaired route manifest at $OUTPUT_FILE"; exit 1; }
grep -Fq 'kind: HTTPRoute' "$OUTPUT_FILE" || { echo "Exported manifest must contain an HTTPRoute"; exit 1; }
grep -Fq 'name: app-routes' "$OUTPUT_FILE" || { echo "Exported manifest must contain app-routes metadata"; exit 1; }

echo "Backends are ready and the repaired HTTPRoute manifest is exported"
