#!/bin/bash
set -e

DEPLOYMENT="web-frontend"
NAMESPACE="app-team"
EXPECTED_IMAGE="nginx:1.27.0-alpine"

ACTUAL_IMAGE=$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || true)

if [ "$ACTUAL_IMAGE" = "$EXPECTED_IMAGE" ]; then
  echo "Deployment '$DEPLOYMENT' uses image '$EXPECTED_IMAGE'"
  exit 0
fi

echo "Expected image '$EXPECTED_IMAGE', got '${ACTUAL_IMAGE:-missing}'"
exit 1
