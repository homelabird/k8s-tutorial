# CKA 2026 Single Domain Drill - etcd Backup and Restore Workflow

## Question 1: repair the etcd recovery planning brief and export the checklist

Repair the etcd recovery planning brief and export both the repaired manifest and a plain-text backup/restore checklist.

```bash
cat <<'EOF_PLAN' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: etcd-recovery-plan
  namespace: etcd-lab
data:
  snapshotPath: /var/backups/etcd/snapshot.db
  endpoint: https://127.0.0.1:2379
  caPath: /etc/kubernetes/pki/etcd/ca.crt
  certPath: /etc/kubernetes/pki/etcd/server.crt
  keyPath: /etc/kubernetes/pki/etcd/server.key
  snapshotCommand: ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key snapshot save /var/backups/etcd/snapshot.db
  restoreCommand: ETCDCTL_API=3 etcdctl snapshot restore /var/backups/etcd/snapshot.db --data-dir=/var/lib/etcd-restore
  staticPodManifest: /etc/kubernetes/manifests/etcd.yaml
EOF_PLAN

mkdir -p /tmp/exam/q1
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/etcd-recovery-checklist.txt
Snapshot
- ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key snapshot save /var/backups/etcd/snapshot.db

Restore
- ETCDCTL_API=3 etcdctl snapshot restore /var/backups/etcd/snapshot.db --data-dir=/var/lib/etcd-restore

Static Pod Update
- edit /etc/kubernetes/manifests/etcd.yaml to point at /var/lib/etcd-restore

Verification
- ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key endpoint health
EOF_CHECKLIST

kubectl get configmap etcd-recovery-plan -n etcd-lab -o yaml > /tmp/exam/q1/etcd-recovery-plan.yaml
```

Expected checks:

- `etcd-recovery-plan` contains the intended snapshot path, certificates, endpoint, and exact snapshot/restore commands
- `/tmp/exam/q1/etcd-recovery-checklist.txt` contains the required sections and exact command lines
- `/tmp/exam/q1/etcd-recovery-plan.yaml` exports the repaired manifest
- stale unsafe paths such as `/backup/old.db`, `/etc/kubernetes/pki/etcd/peer.crt`, and commands that delete `/var/lib/etcd` are removed
