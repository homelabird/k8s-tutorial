#!/bin/bash
set -euo pipefail

EXPORT_FILE="/tmp/exam/q801/disruption-planning-checklist.txt"
[ -f "$EXPORT_FILE" ] || { echo "Expected checklist export at $EXPORT_FILE"; exit 1; }

grep -Fxq 'PDB Inventory' "$EXPORT_FILE" || { echo "Checklist missing PDB Inventory section"; exit 1; }
grep -Fxq 'Node Workload Audit' "$EXPORT_FILE" || { echo "Checklist missing Node Workload Audit section"; exit 1; }
grep -Fxq 'Safe Drain Sequence' "$EXPORT_FILE" || { echo "Checklist missing Safe Drain Sequence section"; exit 1; }
grep -Fq 'kubectl get pdb -A' "$EXPORT_FILE" || { echo "Checklist missing PDB inventory step"; exit 1; }
grep -Fq 'kubectl describe pdb api-pdb -n disruption-lab' "$EXPORT_FILE" || { echo "Checklist missing PDB describe step"; exit 1; }
grep -Fq 'kubectl get pods -A -o wide --field-selector spec.nodeName=kind-cluster-worker' "$EXPORT_FILE" || { echo "Checklist missing node workload audit step"; exit 1; }
grep -Fq 'kubectl get deploy api -n disruption-lab' "$EXPORT_FILE" || { echo "Checklist missing workload ownership audit step"; exit 1; }
grep -Fq 'kubectl cordon kind-cluster-worker' "$EXPORT_FILE" || { echo "Checklist missing cordon step"; exit 1; }
grep -Fq 'kubectl drain kind-cluster-worker --ignore-daemonsets --delete-emptydir-data --dry-run=client' "$EXPORT_FILE" || { echo "Checklist missing drain preview step"; exit 1; }
grep -Fq 'review PodDisruptionBudget impact before any non-dry-run drain' "$EXPORT_FILE" || { echo "Checklist missing safe drain note"; exit 1; }
grep -Fq 'kubectl uncordon kind-cluster-worker' "$EXPORT_FILE" || { echo "Checklist missing uncordon step"; exit 1; }

echo "disruption planning checklist export is valid"
