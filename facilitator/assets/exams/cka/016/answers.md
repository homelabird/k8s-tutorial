# CKA 2026 Single Domain Drill - Kubeadm Lifecycle Planning

## Question 1: repair the kubeadm upgrade brief and export the execution checklist

Repair the upgrade planning brief and export both the repaired manifest and a plain-text execution checklist.

```bash
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: upgrade-brief
  namespace: kubeadm-lab
data:
  currentVersion: v1.31.5
  targetVersion: v1.31.8
  controlPlaneEndpoint: k8s-api-server:6443
  maintenanceNode: cp-maint-0
  planCommand: kubeadm upgrade plan v1.31.8
  applyCommand: kubeadm upgrade apply v1.31.8 -y
  drainCommand: kubectl drain cp-maint-0 --ignore-daemonsets --delete-emptydir-data
  uncordonCommand: kubectl uncordon cp-maint-0
  backupPaths: /etc/kubernetes/admin.conf,/etc/kubernetes/pki,/var/lib/etcd
EOF_BRIEF

mkdir -p /tmp/exam/q1
cat <<'EOF_PLAN' > /tmp/exam/q1/upgrade-plan.txt
Pre-flight
- kubectl get nodes -o wide
- kubeadm upgrade plan v1.31.8

Backups
- /etc/kubernetes/admin.conf
- /etc/kubernetes/pki
- /var/lib/etcd

Execution
- kubectl drain cp-maint-0 --ignore-daemonsets --delete-emptydir-data
- kubeadm upgrade apply v1.31.8 -y

Post-upgrade
- kubectl uncordon cp-maint-0
- kubectl get nodes -o wide
EOF_PLAN

kubectl get configmap upgrade-brief -n kubeadm-lab -o yaml > /tmp/exam/q1/upgrade-brief.yaml
```

Expected checks:

- `upgrade-brief` contains the intended target version, endpoint, backup paths, and safe command sequence
- `/tmp/exam/q1/upgrade-plan.txt` contains the required sections and exact kubeadm / drain / uncordon commands
- `/tmp/exam/q1/upgrade-brief.yaml` exports the repaired manifest
- stale commands such as `kubeadm upgrade node` and `kubectl cordon cp-maint-0` are removed

