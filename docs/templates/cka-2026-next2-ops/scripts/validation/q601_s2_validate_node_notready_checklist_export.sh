#!/bin/bash
set -euo pipefail

EXPORT_FILE="/tmp/exam/q601/node-notready-checklist.txt"
[ -f "$EXPORT_FILE" ] || { echo "Expected checklist export at $EXPORT_FILE"; exit 1; }

grep -Fxq 'Node Conditions' "$EXPORT_FILE" || { echo "Checklist missing Node Conditions section"; exit 1; }
grep -Fxq 'Kubelet Service' "$EXPORT_FILE" || { echo "Checklist missing Kubelet Service section"; exit 1; }
grep -Fxq 'Runtime and Config' "$EXPORT_FILE" || { echo "Checklist missing Runtime and Config section"; exit 1; }
grep -Fq 'kubectl get nodes' "$EXPORT_FILE" || { echo "Checklist missing node list step"; exit 1; }
grep -Fq 'kubectl describe node kind-cluster-worker | grep -A3 Conditions' "$EXPORT_FILE" || { echo "Checklist missing node condition check"; exit 1; }
grep -Fq 'sudo systemctl status kubelet' "$EXPORT_FILE" || { echo "Checklist missing kubelet service check"; exit 1; }
grep -Fq 'sudo journalctl -u kubelet -n 50' "$EXPORT_FILE" || { echo "Checklist missing kubelet log check"; exit 1; }
grep -Fq 'sudo crictl info' "$EXPORT_FILE" || { echo "Checklist missing runtime check"; exit 1; }
grep -Fq 'sudo test -f /var/lib/kubelet/config.yaml' "$EXPORT_FILE" || { echo "Checklist missing config check"; exit 1; }

echo "node notready checklist export is valid"
