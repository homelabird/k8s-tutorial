#!/bin/bash
set -euo pipefail

EXPORT_FILE="/tmp/exam/q604/runtime-diagnostics-checklist.txt"
[ -f "$EXPORT_FILE" ] || { echo "Expected checklist export at $EXPORT_FILE"; exit 1; }

grep -Fxq 'Kubelet Wiring' "$EXPORT_FILE" || { echo "Checklist missing Kubelet Wiring section"; exit 1; }
grep -Fxq 'CRI Connectivity' "$EXPORT_FILE" || { echo "Checklist missing CRI Connectivity section"; exit 1; }
grep -Fxq 'Runtime Service' "$EXPORT_FILE" || { echo "Checklist missing Runtime Service section"; exit 1; }
grep -Fq 'sudo grep -n containerRuntimeEndpoint /var/lib/kubelet/config.yaml' "$EXPORT_FILE" || { echo "Checklist missing kubelet runtime endpoint inspection"; exit 1; }
grep -Fq 'sudo test -f /var/lib/kubelet/config.yaml' "$EXPORT_FILE" || { echo "Checklist missing kubelet config existence check"; exit 1; }
grep -Fq 'sudo test -S /run/containerd/containerd.sock' "$EXPORT_FILE" || { echo "Checklist missing runtime socket check"; exit 1; }
grep -Fq 'sudo crictl --runtime-endpoint unix:///run/containerd/containerd.sock info' "$EXPORT_FILE" || { echo "Checklist missing crictl info check"; exit 1; }
grep -Fq 'sudo crictl --runtime-endpoint unix:///run/containerd/containerd.sock pods' "$EXPORT_FILE" || { echo "Checklist missing crictl pods check"; exit 1; }
grep -Fq 'sudo systemctl status containerd' "$EXPORT_FILE" || { echo "Checklist missing runtime service status check"; exit 1; }
grep -Fq 'sudo crictl --runtime-endpoint unix:///run/containerd/containerd.sock ps -a' "$EXPORT_FILE" || { echo "Checklist missing crictl ps -a check"; exit 1; }

echo "runtime diagnostics checklist export is valid"
