#!/bin/bash
set -euo pipefail

NAMESPACE="runtime-lab"
CONFIGMAP="runtime-diagnostics-brief"
OUTPUT_DIR="/tmp/exam/q1"

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR/runtime-diagnostics-brief.yaml" "$OUTPUT_DIR/runtime-diagnostics-checklist.txt"

cat <<'EOF_BRIEF' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: ConfigMap
metadata:
  name: runtime-diagnostics-brief
  namespace: runtime-lab
data:
  targetNode: kind-cluster-worker
  kubeletConfigCheck: sudo grep -n runtimeRequestTimeout /var/lib/kubelet/config.yaml
  runtimeSocketCheck: sudo test -S /var/run/dockershim.sock
  crictlInfoCheck: sudo crictl info
  crictlPodsCheck: sudo crictl ps
  runtimeServiceCheck: sudo systemctl restart containerd
EOF_BRIEF

cat <<'EOF_STALE' > "$OUTPUT_DIR/runtime-diagnostics-checklist.txt"
Kubelet Wiring
- sudo sed -i 's#containerRuntimeEndpoint: .*#containerRuntimeEndpoint: unix:///var/run/dockershim.sock#' /var/lib/kubelet/config.yaml

CRI Connectivity
- sudo crictl info
- sudo crictl ps

Runtime Service
- sudo systemctl stop containerd
- sudo systemctl restart kubelet
EOF_STALE

exit 0
