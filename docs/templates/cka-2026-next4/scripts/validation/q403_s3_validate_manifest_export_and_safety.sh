#!/bin/bash
set -euo pipefail

MANIFEST_FILE="/tmp/exam/q403/upgrade-brief.yaml"

[ -f "$MANIFEST_FILE" ] || { echo "Expected repaired manifest export at $MANIFEST_FILE"; exit 1; }

grep -Fq 'name: upgrade-brief' "$MANIFEST_FILE" || { echo "Exported manifest must reference upgrade-brief"; exit 1; }
grep -Fq 'namespace: kubeadm-lab' "$MANIFEST_FILE" || { echo "Exported manifest must stay in kubeadm-lab"; exit 1; }
grep -Fq 'targetVersion: v1.31.8' "$MANIFEST_FILE" || { echo "Exported manifest must include targetVersion v1.31.8"; exit 1; }
grep -Fq 'controlPlaneEndpoint: k8s-api-server:6443' "$MANIFEST_FILE" || { echo "Exported manifest must include the repaired endpoint"; exit 1; }

if grep -Fq 'kubeadm upgrade node' "$MANIFEST_FILE"; then
  echo "Stale kubeadm upgrade node command must not remain in the exported manifest"
  exit 1
fi

if grep -Fq 'kubectl cordon cp-maint-0' "$MANIFEST_FILE"; then
  echo "Unsafe cordon command must not remain in the exported manifest"
  exit 1
fi

echo "Repaired manifest export is present and stale unsafe commands are removed"
