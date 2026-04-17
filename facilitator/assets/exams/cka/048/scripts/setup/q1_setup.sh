#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="dnspolicy-lab"
OUTPUT_DIR="/tmp/exam/q1"

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl -n "$NAMESPACE" delete pod dns-client --ignore-not-found >/dev/null
kubectl -n "$NAMESPACE" delete configmap dns-diagnostics-brief --ignore-not-found >/dev/null

cat <<'EOF_POD' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: Pod
metadata:
  name: dns-client
  namespace: dnspolicy-lab
  labels:
    app: dns-client
spec:
  restartPolicy: Always
  dnsPolicy: None
  dnsConfig:
    nameservers:
      - 1.1.1.1
    searches:
      - lab.local
    options:
      - name: ndots
        value: "2"
  containers:
    - name: toolbox
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
EOF_POD

kubectl wait --for=condition=Ready pod/dns-client -n "$NAMESPACE" --timeout=120s >/dev/null

cat <<'EOF_CM' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: ConfigMap
metadata:
  name: dns-diagnostics-brief
  namespace: dnspolicy-lab
data:
  targetWorkload: dns-client-old
  podInventory: kubectl get pod -n dnspolicy-lab
  dnsPolicyCheck: kubectl rollout restart deployment dns-client -n dnspolicy-lab
  dnsNameserverCheck: kubectl edit pod dns-client -n dnspolicy-lab
  dnsSearchCheck: kubectl get svc kube-dns -n kube-system
  dnsOptionCheck: kubectl patch deployment dns-client -n dnspolicy-lab --type merge -p '{}'
  resolverFileCheck: kubectl get pod dns-client -n dnspolicy-lab -o jsonpath='{.status.podIP}'
  eventCheck: kubectl get configmap -n dnspolicy-lab
  safeManifestNote: restart the workload and patch cluster DNS services until resolver settings look correct
EOF_CM

mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR/dns-diagnostics-brief.yaml" "$OUTPUT_DIR/dns-diagnostics-checklist.txt"
