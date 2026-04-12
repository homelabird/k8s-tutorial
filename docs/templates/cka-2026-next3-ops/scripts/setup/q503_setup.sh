#!/bin/bash
set -euo pipefail

NAMESPACE="service-debug-lab"
CONFIGMAP="service-exposure-brief"
OUTPUT_DIR="/tmp/exam/q503"

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR/service-exposure-brief.yaml" "$OUTPUT_DIR/service-exposure-checklist.txt"

cat <<'EOF_BRIEF' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: ConfigMap
metadata:
  name: service-exposure-brief
  namespace: service-debug-lab
data:
  serviceName: web-svc
  serviceType: NodePort
  selectorKey: component
  selectorValue: web
  servicePort: "9090"
  targetPort: "9090"
  endpointCheck: kubectl get endpoints web-svc -n service-debug-lab
  selectorCheck: kubectl get svc web-svc -n service-debug-lab -o jsonpath='{.spec.selector.component}'
  reachabilityCheck: kubectl exec -n service-debug-lab curlpod -- curl -sS http://web-svc:9090/status
EOF_BRIEF

cat <<'EOF_STALE' > "$OUTPUT_DIR/service-exposure-checklist.txt"
Selector Audit
- kubectl patch deployment echo-api -n service-debug-lab --type merge -p '{"spec":{"template":{"metadata":{"labels":{"app":"echo-api"}}}}}'

Reachability
- kubectl delete svc echo-api -n service-debug-lab
EOF_STALE

exit 0
