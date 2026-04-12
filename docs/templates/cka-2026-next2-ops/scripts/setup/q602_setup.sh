#!/bin/bash
set -euo pipefail

NAMESPACE="pki-lab"
CONFIGMAP="certificate-renewal-brief"
OUTPUT_DIR="/tmp/exam/q602"

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR/certificate-renewal-brief.yaml" "$OUTPUT_DIR/certificate-expiry-checklist.txt"

cat <<'EOF_BRIEF' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: ConfigMap
metadata:
  name: certificate-renewal-brief
  namespace: pki-lab
data:
  targetCertificate: /etc/kubernetes/pki/etcd/server.crt
  expiryCheck: sudo kubeadm upgrade plan
  dateInspection: sudo openssl x509 -in /etc/kubernetes/pki/apiserver.key -noout -dates
  kubeconfigCheck: sudo ls /etc/kubernetes/pki
  renewalCommand: sudo kubeadm reset -f
  readinessCheck: sudo systemctl restart kubelet
EOF_BRIEF

cat <<'EOF_STALE' > "$OUTPUT_DIR/certificate-expiry-checklist.txt"
Certificate Inspection
- sudo kubeadm upgrade plan

Renewal Planning
- sudo kubeadm reset -f
- sudo rm -f /etc/kubernetes/manifests/kube-apiserver.yaml

Post-Renewal Verification
- sudo systemctl restart kubelet
EOF_STALE

exit 0
