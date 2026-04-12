#!/bin/bash
set -euo pipefail

EXPORT_FILE="/tmp/exam/q1/service-exposure-checklist.txt"
[ -f "$EXPORT_FILE" ] || { echo "Expected checklist export at $EXPORT_FILE"; exit 1; }

grep -Fxq 'Selector Audit' "$EXPORT_FILE" || { echo "Checklist missing Selector Audit section"; exit 1; }
grep -Fxq 'Endpoint Audit' "$EXPORT_FILE" || { echo "Checklist missing Endpoint Audit section"; exit 1; }
grep -Fxq 'Reachability' "$EXPORT_FILE" || { echo "Checklist missing Reachability section"; exit 1; }
grep -Fq "kubectl get svc echo-api -n service-debug-lab -o yaml" "$EXPORT_FILE" || { echo "Checklist missing Service inspection step"; exit 1; }
grep -Fq "kubectl get svc echo-api -n service-debug-lab -o jsonpath='{.spec.selector.app}'" "$EXPORT_FILE" || { echo "Checklist missing selector inspection step"; exit 1; }
grep -Fq "kubectl get endpoints echo-api -n service-debug-lab -o wide" "$EXPORT_FILE" || { echo "Checklist missing endpoints inspection step"; exit 1; }
grep -Fq "kubectl get endpointslices -n service-debug-lab -l kubernetes.io/service-name=echo-api" "$EXPORT_FILE" || { echo "Checklist missing EndpointSlice inspection step"; exit 1; }
grep -Fq "kubectl exec -n service-debug-lab net-debug -- wget -qO- http://echo-api:8080/healthz" "$EXPORT_FILE" || { echo "Checklist missing reachability probe"; exit 1; }
grep -Fq "kubectl get svc echo-api -n service-debug-lab -o jsonpath='{.spec.ports[0].targetPort}'" "$EXPORT_FILE" || { echo "Checklist missing targetPort inspection step"; exit 1; }

echo "service exposure checklist export is valid"
