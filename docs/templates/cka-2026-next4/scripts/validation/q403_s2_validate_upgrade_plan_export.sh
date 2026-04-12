#!/bin/bash
set -euo pipefail

PLAN_FILE="/tmp/exam/q403/upgrade-plan.txt"

[ -f "$PLAN_FILE" ] || { echo "Expected plan export at $PLAN_FILE"; exit 1; }

grep -Fq 'Pre-flight' "$PLAN_FILE" || { echo "Plan file must include Pre-flight section"; exit 1; }
grep -Fq 'Backups' "$PLAN_FILE" || { echo "Plan file must include Backups section"; exit 1; }
grep -Fq 'Execution' "$PLAN_FILE" || { echo "Plan file must include Execution section"; exit 1; }
grep -Fq 'Post-upgrade' "$PLAN_FILE" || { echo "Plan file must include Post-upgrade section"; exit 1; }
grep -Fq 'kubeadm upgrade plan v1.31.8' "$PLAN_FILE" || { echo "Plan file must include kubeadm upgrade plan"; exit 1; }
grep -Fq 'kubectl drain cp-maint-0 --ignore-daemonsets --delete-emptydir-data' "$PLAN_FILE" || { echo "Plan file must include safe drain command"; exit 1; }
grep -Fq 'kubeadm upgrade apply v1.31.8 -y' "$PLAN_FILE" || { echo "Plan file must include kubeadm upgrade apply"; exit 1; }
grep -Fq 'kubectl uncordon cp-maint-0' "$PLAN_FILE" || { echo "Plan file must include uncordon command"; exit 1; }
grep -Fq '/etc/kubernetes/admin.conf' "$PLAN_FILE" || { echo "Plan file must mention admin.conf backup"; exit 1; }
grep -Fq '/etc/kubernetes/pki' "$PLAN_FILE" || { echo "Plan file must mention pki backup"; exit 1; }
grep -Fq '/var/lib/etcd' "$PLAN_FILE" || { echo "Plan file must mention etcd backup"; exit 1; }

echo "Upgrade planning checklist export is present"
