#!/bin/bash
set -euo pipefail

NAMESPACE="etcd-lab"
CONFIGMAP="etcd-recovery-plan"
OUTPUT_DIR="/tmp/exam/q1"

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR/etcd-recovery-plan.yaml" "$OUTPUT_DIR/etcd-recovery-checklist.txt"

cat <<'EOF_PLAN' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: ConfigMap
metadata:
  name: etcd-recovery-plan
  namespace: etcd-lab
data:
  snapshotPath: /backup/old.db
  endpoint: https://10.0.0.10:2379
  caPath: /etc/kubernetes/pki/etcd/peer.crt
  certPath: /etc/kubernetes/pki/etcd/peer.crt
  keyPath: /etc/kubernetes/pki/etcd/peer.key
  snapshotCommand: ETCDCTL_API=3 etcdctl snapshot save /backup/old.db
  restoreCommand: ETCDCTL_API=3 etcdctl snapshot restore /backup/old.db --data-dir=/var/lib/etcd
  staticPodManifest: /etc/kubernetes/manifests/kube-apiserver.yaml
EOF_PLAN

cat <<'EOF_STALE' > "$OUTPUT_DIR/etcd-recovery-checklist.txt"
Snapshot
- ETCDCTL_API=3 etcdctl snapshot save /backup/old.db

Restore
- rm -rf /var/lib/etcd
- ETCDCTL_API=3 etcdctl snapshot restore /backup/old.db --data-dir=/var/lib/etcd
EOF_STALE

exit 0
