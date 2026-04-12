#!/bin/bash
set -euo pipefail

EXPORT_FILE="/tmp/exam/q502/connectivity-matrix.txt"
[ -f "$EXPORT_FILE" ] || { echo "Expected connectivity matrix export at $EXPORT_FILE"; exit 1; }

grep -Fxq 'Service Path' "$EXPORT_FILE" || { echo "Matrix missing Service Path section"; exit 1; }
grep -Fxq 'Pod Path' "$EXPORT_FILE" || { echo "Matrix missing Pod Path section"; exit 1; }
grep -Fxq 'DNS Checks' "$EXPORT_FILE" || { echo "Matrix missing DNS Checks section"; exit 1; }
grep -Fq 'kubectl exec -n connectivity-lab net-debug -- wget -qO- http://echo-api:8080/healthz' "$EXPORT_FILE" || { echo "Matrix missing service probe"; exit 1; }
grep -Fq 'kubectl exec -n connectivity-lab net-debug -- wget -qO- http://echo-api-0.echo-api-headless.connectivity-lab.svc.cluster.local:8080/healthz' "$EXPORT_FILE" || { echo "Matrix missing pod probe"; exit 1; }
grep -Fq 'kubectl exec -n connectivity-lab net-debug -- nslookup echo-api.connectivity-lab.svc.cluster.local' "$EXPORT_FILE" || { echo "Matrix missing DNS probe"; exit 1; }
grep -Fq 'kubectl get svc echo-api -n connectivity-lab' "$EXPORT_FILE" || { echo "Matrix missing Service inspection step"; exit 1; }
grep -Fq 'kubectl get svc echo-api-headless -n connectivity-lab' "$EXPORT_FILE" || { echo "Matrix missing headless Service inspection step"; exit 1; }

echo "connectivity matrix export is valid"
