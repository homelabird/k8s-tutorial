#!/bin/bash
set -e

NAMESPACE="app-team"

if kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
  echo "Namespace '$NAMESPACE' exists"
  exit 0
fi

echo "Namespace '$NAMESPACE' not found"
exit 1
