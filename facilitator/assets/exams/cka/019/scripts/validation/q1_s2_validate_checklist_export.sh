#!/bin/bash
set -euo pipefail

EXPORT_FILE="/tmp/exam/q1/control-plane-checklist.txt"
[ -f "$EXPORT_FILE" ] || { echo "Expected checklist export at $EXPORT_FILE"; exit 1; }

grep -Fxq 'Scheduler' "$EXPORT_FILE" || { echo "Checklist missing Scheduler section"; exit 1; }
grep -Fxq 'Controller Manager' "$EXPORT_FILE" || { echo "Checklist missing Controller Manager section"; exit 1; }
grep -Fxq 'Verification' "$EXPORT_FILE" || { echo "Checklist missing Verification section"; exit 1; }
grep -Fq 'inspect /etc/kubernetes/manifests/kube-scheduler.yaml' "$EXPORT_FILE" || { echo "Checklist missing scheduler manifest inspection step"; exit 1; }
grep -Fq 'confirm /etc/kubernetes/scheduler.conf' "$EXPORT_FILE" || { echo "Checklist missing scheduler kubeconfig step"; exit 1; }
grep -Fq 'curl -k https://127.0.0.1:10259/healthz' "$EXPORT_FILE" || { echo "Checklist missing scheduler healthz step"; exit 1; }
grep -Fq 'journalctl -u kubelet | grep kube-scheduler' "$EXPORT_FILE" || { echo "Checklist missing scheduler log hint"; exit 1; }
grep -Fq 'inspect /etc/kubernetes/manifests/kube-controller-manager.yaml' "$EXPORT_FILE" || { echo "Checklist missing controller-manager manifest inspection step"; exit 1; }
grep -Fq 'confirm /etc/kubernetes/controller-manager.conf' "$EXPORT_FILE" || { echo "Checklist missing controller-manager kubeconfig step"; exit 1; }
grep -Fq 'curl -k https://127.0.0.1:10257/healthz' "$EXPORT_FILE" || { echo "Checklist missing controller-manager healthz step"; exit 1; }
grep -Fq 'journalctl -u kubelet | grep kube-controller-manager' "$EXPORT_FILE" || { echo "Checklist missing controller-manager log hint"; exit 1; }
grep -Fq 'kubectl get pods -n kube-system -l component=kube-scheduler' "$EXPORT_FILE" || { echo "Checklist missing scheduler verification step"; exit 1; }
grep -Fq 'kubectl get pods -n kube-system -l component=kube-controller-manager' "$EXPORT_FILE" || { echo "Checklist missing controller-manager verification step"; exit 1; }
grep -Fq "kubectl get --raw='/readyz?verbose'" "$EXPORT_FILE" || { echo "Checklist missing readyz verification step"; exit 1; }

echo "control plane troubleshooting checklist export is valid"
