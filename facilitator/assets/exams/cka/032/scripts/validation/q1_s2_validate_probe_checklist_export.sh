#!/bin/bash
set -euo pipefail

EXPORT_FILE="/tmp/exam/q1/probe-diagnostics-checklist.txt"
[ -f "$EXPORT_FILE" ] || { echo "Expected checklist export at $EXPORT_FILE"; exit 1; }

grep -Fxq 'Deployment Inventory' "$EXPORT_FILE" || { echo "Checklist missing Deployment Inventory section"; exit 1; }
grep -Fxq 'Probe Checks' "$EXPORT_FILE" || { echo "Checklist missing Probe Checks section"; exit 1; }
grep -Fxq 'Safe Manifest Review' "$EXPORT_FILE" || { echo "Checklist missing Safe Manifest Review section"; exit 1; }
grep -Fq 'kubectl get deployment health-api -n probe-lab -o wide' "$EXPORT_FILE" || { echo "Checklist missing deployment inventory step"; exit 1; }
grep -Fq "kubectl get deployment health-api -n probe-lab -o jsonpath='{.spec.template.spec.containers[0].ports[0].containerPort}'" "$EXPORT_FILE" || { echo "Checklist missing port check step"; exit 1; }
grep -Fq "kubectl get deployment health-api -n probe-lab -o jsonpath='{.spec.template.spec.containers[0].startupProbe.httpGet.path}'" "$EXPORT_FILE" || { echo "Checklist missing startup probe step"; exit 1; }
grep -Fq "kubectl get deployment health-api -n probe-lab -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.httpGet.path}'" "$EXPORT_FILE" || { echo "Checklist missing liveness probe step"; exit 1; }
grep -Fq "kubectl get deployment health-api -n probe-lab -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.path}'" "$EXPORT_FILE" || { echo "Checklist missing readiness probe step"; exit 1; }
grep -Fq 'kubectl get events -n probe-lab --sort-by=.lastTimestamp' "$EXPORT_FILE" || { echo "Checklist missing event check step"; exit 1; }
grep -Fq 'confirm startup, liveness, readiness probe paths and thresholds before changing the Deployment manifest' "$EXPORT_FILE" || { echo "Checklist missing safe manifest note"; exit 1; }

echo "probe diagnostics checklist export is valid"
