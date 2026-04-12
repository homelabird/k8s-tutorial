#!/bin/bash
set -euo pipefail

NAMESPACE="etcd-lab"
CONFIGMAP="etcd-recovery-plan"

kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" >/dev/null 2>&1 || {
  echo "ConfigMap $CONFIGMAP not found"
  exit 1
}

get_key() {
  kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" -o jsonpath="{.data.$1}"
}

[ "$(get_key snapshotPath)" = "/var/backups/etcd/snapshot.db" ] || { echo "snapshotPath must be /var/backups/etcd/snapshot.db"; exit 1; }
[ "$(get_key endpoint)" = "https://127.0.0.1:2379" ] || { echo "endpoint must be https://127.0.0.1:2379"; exit 1; }
[ "$(get_key caPath)" = "/etc/kubernetes/pki/etcd/ca.crt" ] || { echo "caPath must be /etc/kubernetes/pki/etcd/ca.crt"; exit 1; }
[ "$(get_key certPath)" = "/etc/kubernetes/pki/etcd/server.crt" ] || { echo "certPath must be /etc/kubernetes/pki/etcd/server.crt"; exit 1; }
[ "$(get_key keyPath)" = "/etc/kubernetes/pki/etcd/server.key" ] || { echo "keyPath must be /etc/kubernetes/pki/etcd/server.key"; exit 1; }
[ "$(get_key staticPodManifest)" = "/etc/kubernetes/manifests/etcd.yaml" ] || { echo "staticPodManifest must be /etc/kubernetes/manifests/etcd.yaml"; exit 1; }
[ "$(get_key snapshotCommand)" = "ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key snapshot save /var/backups/etcd/snapshot.db" ] || { echo "snapshotCommand does not match expected etcdctl save command"; exit 1; }
[ "$(get_key restoreCommand)" = "ETCDCTL_API=3 etcdctl snapshot restore /var/backups/etcd/snapshot.db --data-dir=/var/lib/etcd-restore" ] || { echo "restoreCommand does not match expected restore command"; exit 1; }

echo "etcd recovery plan contract is repaired"
