#!/bin/bash
set -euo pipefail

EXPORT_FILE="/tmp/exam/q901/stateful-identity-checklist.txt"
[ -f "$EXPORT_FILE" ] || { echo "Expected checklist export at $EXPORT_FILE"; exit 1; }

grep -Fxq 'StatefulSet Inventory' "$EXPORT_FILE" || { echo "Checklist missing StatefulSet Inventory section"; exit 1; }
grep -Fxq 'Stable Network Identity' "$EXPORT_FILE" || { echo "Checklist missing Stable Network Identity section"; exit 1; }
grep -Fxq 'Safe Manifest Review' "$EXPORT_FILE" || { echo "Checklist missing Safe Manifest Review section"; exit 1; }
grep -Fq 'kubectl get statefulset web -n stateful-lab -o wide' "$EXPORT_FILE" || { echo "Checklist missing StatefulSet inventory step"; exit 1; }
grep -Fq 'kubectl get pods -n stateful-lab -l app=web -o wide' "$EXPORT_FILE" || { echo "Checklist missing pod inventory step"; exit 1; }
grep -Fq 'kubectl get svc web-svc -n stateful-lab -o yaml' "$EXPORT_FILE" || { echo "Checklist missing headless service inspection step"; exit 1; }
grep -Fq 'kubectl exec -n stateful-lab dns-debug -- nslookup web-0.web-svc.stateful-lab.svc.cluster.local' "$EXPORT_FILE" || { echo "Checklist missing ordinal DNS step"; exit 1; }
grep -Fq 'kubectl get pvc -n stateful-lab' "$EXPORT_FILE" || { echo "Checklist missing pvc inventory step"; exit 1; }
grep -Fq 'confirm serviceName: web-svc and stable pod ordinals before changing manifests' "$EXPORT_FILE" || { echo "Checklist missing safe manifest note"; exit 1; }

echo "stateful identity checklist export is valid"
