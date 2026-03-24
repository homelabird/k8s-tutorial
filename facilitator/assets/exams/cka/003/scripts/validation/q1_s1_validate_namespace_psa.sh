#!/bin/bash
set -e

NAMESPACE="secure-workloads"
ENFORCE=$(kubectl get namespace "$NAMESPACE" -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' 2>/dev/null || true)
VERSION=$(kubectl get namespace "$NAMESPACE" -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce-version}' 2>/dev/null || true)

if [ "$ENFORCE" = "restricted" ] && [ "$VERSION" = "latest" ]; then
  echo "Namespace '$NAMESPACE' has correct PSA labels"
  exit 0
fi

echo "Expected enforce=restricted and enforce-version=latest, got enforce='${ENFORCE:-missing}' version='${VERSION:-missing}'"
exit 1
