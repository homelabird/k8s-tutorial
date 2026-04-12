#!/bin/bash
set -euo pipefail

NAMESPACE="config-lab"
DEPLOYMENT="report-viewer"

REPORT_USER_LITERAL="$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="REPORT_USER")].value}')"
REPORT_PASS_LITERAL="$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="REPORT_PASS")].value}')"
REPORT_USER_SECRET="$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="REPORT_USER")].valueFrom.secretKeyRef.name}')"
REPORT_PASS_SECRET="$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="REPORT_PASS")].valueFrom.secretKeyRef.name}')"

[ -z "$REPORT_USER_LITERAL" ] || { echo "REPORT_USER must not be hardcoded"; exit 1; }
[ -z "$REPORT_PASS_LITERAL" ] || { echo "REPORT_PASS must not be hardcoded"; exit 1; }
[ "$REPORT_USER_SECRET" = "report-credentials" ] || { echo "REPORT_USER must stay Secret-backed"; exit 1; }
[ "$REPORT_PASS_SECRET" = "report-credentials" ] || { echo "REPORT_PASS must stay Secret-backed"; exit 1; }

echo "Secret-backed values remain externalized"
