#!/bin/bash
set -euo pipefail

EXPORT_FILE="/tmp/exam/q1/placement-diagnostics-checklist.txt"
[ -f "$EXPORT_FILE" ] || { echo "Expected checklist export at $EXPORT_FILE"; exit 1; }

grep -Fxq 'Deployment Inventory' "$EXPORT_FILE" || { echo "Checklist missing Deployment Inventory section"; exit 1; }
grep -Fxq 'Placement Checks' "$EXPORT_FILE" || { echo "Checklist missing Placement Checks section"; exit 1; }
grep -Fxq 'Safe Manifest Review' "$EXPORT_FILE" || { echo "Checklist missing Safe Manifest Review section"; exit 1; }
grep -Fq "kubectl get deployment api-fleet -n affinity-lab -o wide" "$EXPORT_FILE" || { echo "Checklist missing deployment inventory step"; exit 1; }
grep -Fq "kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.replicas}'" "$EXPORT_FILE" || { echo "Checklist missing replica check step"; exit 1; }
grep -Fq "kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].topologyKey}'" "$EXPORT_FILE" || { echo "Checklist missing anti-affinity topology step"; exit 1; }
grep -Fq "kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].labelSelector.matchLabels.app}'" "$EXPORT_FILE" || { echo "Checklist missing anti-affinity selector step"; exit 1; }
grep -Fq "kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.topologySpreadConstraints[0].topologyKey}'" "$EXPORT_FILE" || { echo "Checklist missing topology spread key step"; exit 1; }
grep -Fq "kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.topologySpreadConstraints[0].maxSkew}'" "$EXPORT_FILE" || { echo "Checklist missing maxSkew step"; exit 1; }
grep -Fq "kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.topologySpreadConstraints[0].whenUnsatisfiable}'" "$EXPORT_FILE" || { echo "Checklist missing whenUnsatisfiable step"; exit 1; }
grep -Fq "kubectl get events -n affinity-lab --sort-by=.lastTimestamp" "$EXPORT_FILE" || { echo "Checklist missing event check step"; exit 1; }
grep -Fq "confirm pod anti-affinity selectors and topology spread constraints before changing the Deployment manifest" "$EXPORT_FILE" || { echo "Checklist missing safe manifest note"; exit 1; }

echo "affinity diagnostics checklist export is valid"
