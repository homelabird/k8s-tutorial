#!/bin/bash
set -e

DEPLOYMENT="web-frontend"
NAMESPACE="app-team"
EXPECTED_REPLICAS="2"

ACTUAL_REPLICAS=$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.replicas}' 2>/dev/null || true)

if [ "$ACTUAL_REPLICAS" = "$EXPECTED_REPLICAS" ]; then
  echo "Deployment '$DEPLOYMENT' has $EXPECTED_REPLICAS replicas"
  exit 0
fi

echo "Expected $EXPECTED_REPLICAS replicas, got '${ACTUAL_REPLICAS:-missing}'"
exit 1
