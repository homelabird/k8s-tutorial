#!/bin/bash
set -euo pipefail

NAMESPACE="rbac-lab"
ROLE_NAME="report-reader"
ROLEBINDING_NAME="report-reader"
SERVICE_ACCOUNT="report-reader"

kubectl get role "$ROLE_NAME" -n "$NAMESPACE" >/dev/null 2>&1 || {
  echo "Role '$ROLE_NAME' not found in namespace '$NAMESPACE'"
  exit 1
}

kubectl get rolebinding "$ROLEBINDING_NAME" -n "$NAMESPACE" >/dev/null 2>&1 || {
  echo "RoleBinding '$ROLEBINDING_NAME' not found in namespace '$NAMESPACE'"
  exit 1
}

ROLE_REF_KIND="$(kubectl get rolebinding "$ROLEBINDING_NAME" -n "$NAMESPACE" -o jsonpath='{.roleRef.kind}')"
ROLE_REF_NAME="$(kubectl get rolebinding "$ROLEBINDING_NAME" -n "$NAMESPACE" -o jsonpath='{.roleRef.name}')"
SUBJECT_KIND="$(kubectl get rolebinding "$ROLEBINDING_NAME" -n "$NAMESPACE" -o jsonpath='{.subjects[0].kind}')"
SUBJECT_NAME="$(kubectl get rolebinding "$ROLEBINDING_NAME" -n "$NAMESPACE" -o jsonpath='{.subjects[0].name}')"
SUBJECT_NAMESPACE="$(kubectl get rolebinding "$ROLEBINDING_NAME" -n "$NAMESPACE" -o jsonpath='{.subjects[0].namespace}')"

[ "$ROLE_REF_KIND" = "Role" ] || {
  echo "RoleBinding must reference a Role, got '$ROLE_REF_KIND'"
  exit 1
}

[ "$ROLE_REF_NAME" = "$ROLE_NAME" ] || {
  echo "RoleBinding references '$ROLE_REF_NAME', expected '$ROLE_NAME'"
  exit 1
}

[ "$SUBJECT_KIND" = "ServiceAccount" ] || {
  echo "RoleBinding subject must be a ServiceAccount, got '$SUBJECT_KIND'"
  exit 1
}

[ "$SUBJECT_NAME" = "$SERVICE_ACCOUNT" ] || {
  echo "RoleBinding subject '$SUBJECT_NAME' does not match '$SERVICE_ACCOUNT'"
  exit 1
}

[ "$SUBJECT_NAMESPACE" = "$NAMESPACE" ] || {
  echo "RoleBinding subject namespace '$SUBJECT_NAMESPACE' does not match '$NAMESPACE'"
  exit 1
}

echo "Role and RoleBinding are namespace-scoped and correctly bound"
