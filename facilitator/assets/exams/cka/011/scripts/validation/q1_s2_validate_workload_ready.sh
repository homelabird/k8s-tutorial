#!/bin/bash
set -euo pipefail

NAMESPACE="config-lab"
DEPLOYMENT="report-viewer"

AVAILABLE="$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.status.availableReplicas}' 2>/dev/null || true)"
[ "${AVAILABLE:-0}" -ge 1 ] || {
  echo "Deployment '$DEPLOYMENT' is not Available"
  exit 1
}

MATCHED_POD=""
while IFS='|' read -r CANDIDATE_NAME DELETION_TS PHASE; do
  [ -n "$CANDIDATE_NAME" ] || continue
  [ -z "$DELETION_TS" ] || continue
  [ "$PHASE" = "Running" ] || continue

  APP_MODE="$(kubectl exec -n "$NAMESPACE" "$CANDIDATE_NAME" -- printenv APP_MODE 2>/dev/null || true)"
  REPORT_USER="$(kubectl exec -n "$NAMESPACE" "$CANDIDATE_NAME" -- printenv REPORT_USER 2>/dev/null || true)"
  REPORT_PASS="$(kubectl exec -n "$NAMESPACE" "$CANDIDATE_NAME" -- printenv REPORT_PASS 2>/dev/null || true)"

  if [ "$APP_MODE" = "production" ] && [ "$REPORT_USER" = "reporter" ] && [ "$REPORT_PASS" = "super-secret-password" ]; then
    MATCHED_POD="$CANDIDATE_NAME"
    break
  fi
done <<EOF_PODS
$(kubectl get pods -n "$NAMESPACE" -l app=report-viewer -o jsonpath='{range .items[*]}{.metadata.name}{"|"}{.metadata.deletionTimestamp}{"|"}{.status.phase}{"\n"}{end}')
EOF_PODS

[ -n "$MATCHED_POD" ] || {
  echo "No active Running Pod exposes the expected ConfigMap and Secret values"
  exit 1
}

echo "report-viewer is Available and consumes the expected configuration values"
