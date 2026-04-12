#!/bin/bash
set -euo pipefail

NAMESPACE="config-lab"
DEPLOYMENT="report-viewer"

APP_MODE_CM="$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="APP_MODE")].valueFrom.configMapKeyRef.name}')"
APP_MODE_KEY="$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="APP_MODE")].valueFrom.configMapKeyRef.key}')"
REPORT_USER_SECRET="$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="REPORT_USER")].valueFrom.secretKeyRef.name}')"
REPORT_USER_KEY="$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="REPORT_USER")].valueFrom.secretKeyRef.key}')"
REPORT_PASS_SECRET="$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="REPORT_PASS")].valueFrom.secretKeyRef.name}')"
REPORT_PASS_KEY="$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="REPORT_PASS")].valueFrom.secretKeyRef.key}')"

[ "$APP_MODE_CM" = "report-config" ] || { echo "APP_MODE must reference ConfigMap report-config"; exit 1; }
[ "$APP_MODE_KEY" = "APP_MODE" ] || { echo "APP_MODE must use key APP_MODE"; exit 1; }
[ "$REPORT_USER_SECRET" = "report-credentials" ] || { echo "REPORT_USER must reference Secret report-credentials"; exit 1; }
[ "$REPORT_USER_KEY" = "username" ] || { echo "REPORT_USER must use Secret key username"; exit 1; }
[ "$REPORT_PASS_SECRET" = "report-credentials" ] || { echo "REPORT_PASS must reference Secret report-credentials"; exit 1; }
[ "$REPORT_PASS_KEY" = "password" ] || { echo "REPORT_PASS must use Secret key password"; exit 1; }

echo "Deployment references the intended ConfigMap and Secret keys"
