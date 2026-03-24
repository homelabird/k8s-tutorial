#!/bin/bash
set -e

DEPLOYMENT="web-frontend"
NAMESPACE="app-team"

if kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" >/dev/null 2>&1; then
  echo "Deployment '$DEPLOYMENT' exists in namespace '$NAMESPACE'"
  exit 0
fi

echo "Deployment '$DEPLOYMENT' not found in namespace '$NAMESPACE'"
exit 1
