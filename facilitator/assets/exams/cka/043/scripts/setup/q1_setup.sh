#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="staticpod-lab"
OUTPUT_DIR="/tmp/exam/q1"

kubectl delete namespace "${NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true
kubectl create namespace "${NAMESPACE}" >/dev/null
mkdir -p "${OUTPUT_DIR}"

cat <<'EOF_POD' | kubectl apply -n "${NAMESPACE}" -f -
apiVersion: v1
kind: Pod
metadata:
  name: audit-agent-ckad9999
spec:
  hostNetwork: true
  nodeName: kind-cluster-control-plane
  containers:
    - name: agent
      image: nginx:1.25.3
      command:
        - /bin/sh
        - -c
        - while true; do echo static-pod-audit; sleep 30; done
EOF_POD

cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: staticpod-diagnostics-brief
  namespace: staticpod-lab
data:
  targetMirrorPod: edge-agent
  mirrorPodInventory: kubectl get pods -n staticpod-lab
  staticPodPathCheck: sudo mv /etc/kubernetes/manifests/audit-agent.yaml /tmp/
  manifestPreviewCheck: sudo systemctl restart kubelet
  hostNetworkCheck: kubectl delete pod audit-agent-ckad9999 -n staticpod-lab
  containerCommandCheck: kubectl edit pod audit-agent-ckad9999 -n staticpod-lab
  nodeCheck: kubectl get pod audit-agent-ckad9999 -n staticpod-lab
  eventCheck: kubectl get pod audit-agent-ckad9999 -n staticpod-lab -o yaml
  safeManifestNote: delete the mirror pod and restart kubelet until the static pod returns
EOF_BRIEF

rm -f "${OUTPUT_DIR}/staticpod-diagnostics-brief.yaml" "${OUTPUT_DIR}/staticpod-diagnostics-checklist.txt"
