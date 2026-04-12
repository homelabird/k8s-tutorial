#!/bin/bash
set -euo pipefail

NAMESPACE="rbac-lab"
ROLE_NAME="report-reader"
SUBJECT="system:serviceaccount:${NAMESPACE}:report-reader"

read_can_i() {
  local value
  value="$(kubectl auth can-i "$@" 2>/dev/null || true)"
  value="$(printf '%s' "$value" | tr -d '\r\n')"
  printf '%s' "$value"
}

VERBS="$(kubectl get role "$ROLE_NAME" -n "$NAMESPACE" -o jsonpath='{.rules[0].verbs[*]}')"
RESOURCES="$(kubectl get role "$ROLE_NAME" -n "$NAMESPACE" -o jsonpath='{.rules[0].resources[*]}')"
CAN_CREATE="$(read_can_i create pods -n "$NAMESPACE" --as="$SUBJECT")"
CAN_GET_SECRETS="$(read_can_i get secrets -n "$NAMESPACE" --as="$SUBJECT")"

[[ "$VERBS" =~ get ]] || {
  echo "Role is missing get"
  exit 1
}
[[ "$VERBS" =~ list ]] || {
  echo "Role is missing list"
  exit 1
}
[[ ! "$VERBS" =~ create|update|patch|delete|watch ]] || {
  echo "Role includes write or extra verbs: $VERBS"
  exit 1
}
[[ "$RESOURCES" = "pods" ]] || {
  echo "Role resources are not limited to pods: $RESOURCES"
  exit 1
}

[[ "$CAN_CREATE" = "no" ]] || {
  echo "ServiceAccount should not be able to create pods: $CAN_CREATE"
  exit 1
}

[[ "$CAN_GET_SECRETS" = "no" ]] || {
  echo "ServiceAccount should not be able to get secrets: $CAN_GET_SECRETS"
  exit 1
}

kubectl get clusterrolebinding report-reader >/dev/null 2>&1 && {
  echo "ClusterRoleBinding report-reader must not exist"
  exit 1
}

echo "Least-privilege constraints are preserved"
