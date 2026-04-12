#!/bin/bash
set -euo pipefail

NAMESPACE="rbac-lab"
SUBJECT="system:serviceaccount:${NAMESPACE}:report-reader"

kubectl auth can-i get pods -n "$NAMESPACE" --as="$SUBJECT" | grep -qx "yes" || {
  echo "ServiceAccount cannot get pods in '$NAMESPACE'"
  exit 1
}

kubectl auth can-i list pods -n "$NAMESPACE" --as="$SUBJECT" | grep -qx "yes" || {
  echo "ServiceAccount cannot list pods in '$NAMESPACE'"
  exit 1
}

echo "ServiceAccount can get and list pods in rbac-lab"
