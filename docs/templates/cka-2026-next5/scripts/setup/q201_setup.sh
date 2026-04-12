#!/bin/bash
set -euo pipefail

NAMESPACE="rbac-lab"
SERVICE_ACCOUNT="report-reader"
TEST_POD="rbac-check"

kubectl create namespace "$NAMESPACE" >/dev/null 2>&1 || true
kubectl create serviceaccount "$SERVICE_ACCOUNT" -n "$NAMESPACE" >/dev/null 2>&1 || true

kubectl delete role report-reader -n "$NAMESPACE" --ignore-not-found=true >/dev/null 2>&1 || true
kubectl delete rolebinding report-reader -n "$NAMESPACE" --ignore-not-found=true >/dev/null 2>&1 || true
kubectl delete clusterrolebinding report-reader --ignore-not-found=true >/dev/null 2>&1 || true

kubectl run "$TEST_POD" \
  -n "$NAMESPACE" \
  --image=nginx:1.25.5 \
  --restart=Never \
  --dry-run=client \
  -o yaml | kubectl apply -f - >/dev/null

exit 0
