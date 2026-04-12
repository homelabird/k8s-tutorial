#!/bin/bash
set -euo pipefail

NAMESPACE="config-lab"
DEPLOYMENT="report-viewer"

AVAILABLE="$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.status.availableReplicas}' 2>/dev/null || true)"
[ "${AVAILABLE:-0}" -ge 1 ] || {
  echo "Deployment '$DEPLOYMENT' is not Available"
  exit 1
}

POD_NAME="$(kubectl get pods -n "$NAMESPACE" -l app=report-viewer -o jsonpath='{range .items[?(@.status.phase=="Running")]}{.metadata.name}{"\n"}{end}' | head -n1)"
[ -n "$POD_NAME" ] || {
  echo "No Running Pod found for report-viewer"
  exit 1
}

APP_MODE="$(kubectl exec -n "$NAMESPACE" "$POD_NAME" -- printenv APP_MODE)"
REPORT_USER="$(kubectl exec -n "$NAMESPACE" "$POD_NAME" -- printenv REPORT_USER)"
REPORT_PASS="$(kubectl exec -n "$NAMESPACE" "$POD_NAME" -- printenv REPORT_PASS)"

[ "$APP_MODE" = "production" ] || { echo "APP_MODE must resolve to production"; exit 1; }
[ "$REPORT_USER" = "reporter" ] || { echo "REPORT_USER must resolve to reporter"; exit 1; }
[ "$REPORT_PASS" = "super-secret-password" ] || { echo "REPORT_PASS must resolve to the expected Secret value"; exit 1; }

echo "report-viewer is Available and consumes the expected configuration values"
