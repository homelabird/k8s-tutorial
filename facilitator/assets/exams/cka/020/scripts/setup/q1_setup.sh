#!/bin/bash
set -euo pipefail

NAMESPACE="connectivity-lab"
CONFIGMAP="connectivity-brief"
OUTPUT_DIR="/tmp/exam/q1"

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR/connectivity-brief.yaml" "$OUTPUT_DIR/connectivity-matrix.txt"

cat <<'EOF_BRIEF' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: ConfigMap
metadata:
  name: connectivity-brief
  namespace: connectivity-lab
data:
  debugPod: curlpod
  serviceName: echo-svc
  servicePort: "9090"
  headlessServiceName: echo-hl
  podDnsName: echo-0.echo-hl.connectivity-lab.svc.cluster.local
  serviceProbe: kubectl exec -n connectivity-lab curlpod -- curl -sS http://echo-svc:9090/status
  podProbe: kubectl exec -n connectivity-lab curlpod -- curl -sS http://echo-0.echo-hl.connectivity-lab.svc.cluster.local:9090/status
  dnsProbe: kubectl exec -n connectivity-lab curlpod -- nslookup example.com
EOF_BRIEF

cat <<'EOF_STALE' > "$OUTPUT_DIR/connectivity-matrix.txt"
Service Path
- kubectl delete svc echo-api -n connectivity-lab

DNS Checks
- kubectl rollout restart deployment echo-api -n connectivity-lab
EOF_STALE

exit 0
