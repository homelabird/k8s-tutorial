#!/bin/bash
set -euo pipefail

EXPORT_FILE="/tmp/exam/q405/etcd-recovery-checklist.txt"
[ -f "$EXPORT_FILE" ] || { echo "Expected checklist export at $EXPORT_FILE"; exit 1; }

grep -Fxq 'Snapshot' "$EXPORT_FILE" || { echo "Checklist missing Snapshot section"; exit 1; }
grep -Fxq 'Restore' "$EXPORT_FILE" || { echo "Checklist missing Restore section"; exit 1; }
grep -Fxq 'Static Pod Update' "$EXPORT_FILE" || { echo "Checklist missing Static Pod Update section"; exit 1; }
grep -Fxq 'Verification' "$EXPORT_FILE" || { echo "Checklist missing Verification section"; exit 1; }
grep -Fq 'ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key snapshot save /var/backups/etcd/snapshot.db' "$EXPORT_FILE" || { echo "Checklist missing expected snapshot command"; exit 1; }
grep -Fq 'ETCDCTL_API=3 etcdctl snapshot restore /var/backups/etcd/snapshot.db --data-dir=/var/lib/etcd-restore' "$EXPORT_FILE" || { echo "Checklist missing expected restore command"; exit 1; }
grep -Fq 'edit /etc/kubernetes/manifests/etcd.yaml to point at /var/lib/etcd-restore' "$EXPORT_FILE" || { echo "Checklist missing static pod update guidance"; exit 1; }
grep -Fq 'ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key endpoint health' "$EXPORT_FILE" || { echo "Checklist missing verification command"; exit 1; }

echo "etcd recovery checklist export is valid"
