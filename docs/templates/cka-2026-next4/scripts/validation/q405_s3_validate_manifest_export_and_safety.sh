#!/bin/bash
set -euo pipefail

EXPORT_FILE="/tmp/exam/q405/etcd-recovery-plan.yaml"
CHECKLIST_FILE="/tmp/exam/q405/etcd-recovery-checklist.txt"

[ -f "$EXPORT_FILE" ] || { echo "Expected manifest export at $EXPORT_FILE"; exit 1; }
grep -Fq 'name: etcd-recovery-plan' "$EXPORT_FILE" || { echo "Exported manifest must contain etcd-recovery-plan"; exit 1; }
grep -Fq 'namespace: etcd-lab' "$EXPORT_FILE" || { echo "Exported manifest must contain namespace etcd-lab"; exit 1; }
grep -Fq 'snapshotPath: /var/backups/etcd/snapshot.db' "$EXPORT_FILE" || { echo "Exported manifest missing repaired snapshotPath"; exit 1; }
grep -Fq 'restoreCommand: ETCDCTL_API=3 etcdctl snapshot restore /var/backups/etcd/snapshot.db --data-dir=/var/lib/etcd-restore' "$EXPORT_FILE" || { echo "Exported manifest missing repaired restoreCommand"; exit 1; }
! grep -Fq '/backup/old.db' "$EXPORT_FILE" || { echo "Exported manifest still contains stale snapshot path"; exit 1; }
! grep -Fq '/etc/kubernetes/pki/etcd/peer.crt' "$EXPORT_FILE" || { echo "Exported manifest still contains peer certificate path"; exit 1; }
! grep -Fq 'rm -rf /var/lib/etcd' "$CHECKLIST_FILE" || { echo "Checklist must not delete /var/lib/etcd"; exit 1; }

echo "etcd manifest export and safety checks passed"
