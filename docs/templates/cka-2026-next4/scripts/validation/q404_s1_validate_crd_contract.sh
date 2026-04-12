#!/bin/bash
set -euo pipefail

CRD_NAME="widgets.training.cka.io"

kubectl get crd "$CRD_NAME" >/dev/null 2>&1 || { echo "CRD $CRD_NAME not found"; exit 1; }

CRD_JSON="$(kubectl get crd "$CRD_NAME" -o json)"

GROUP="$(printf '%s' "$CRD_JSON" | jq -r '.spec.group')"
KIND="$(printf '%s' "$CRD_JSON" | jq -r '.spec.names.kind')"
PLURAL="$(printf '%s' "$CRD_JSON" | jq -r '.spec.names.plural')"
SCOPE="$(printf '%s' "$CRD_JSON" | jq -r '.spec.scope')"
IMAGE_TYPE="$(printf '%s' "$CRD_JSON" | jq -r '.spec.versions[] | select(.name=="v1alpha1") | .schema.openAPIV3Schema.properties.spec.properties.image.type')"
REPLICAS_TYPE="$(printf '%s' "$CRD_JSON" | jq -r '.spec.versions[] | select(.name=="v1alpha1") | .schema.openAPIV3Schema.properties.spec.properties.replicas.type')"

[ "$GROUP" = "training.cka.io" ] || { echo "CRD group must be training.cka.io"; exit 1; }
[ "$KIND" = "Widget" ] || { echo "CRD kind must be Widget"; exit 1; }
[ "$PLURAL" = "widgets" ] || { echo "CRD plural must be widgets"; exit 1; }
[ "$SCOPE" = "Namespaced" ] || { echo "CRD scope must be Namespaced"; exit 1; }
[ "$IMAGE_TYPE" = "string" ] || { echo "spec.image must be string"; exit 1; }
[ "$REPLICAS_TYPE" = "integer" ] || { echo "spec.replicas must be integer"; exit 1; }

printf '%s' "$CRD_JSON" | jq -e '.spec.versions[] | select(.name=="v1alpha1") | .schema.openAPIV3Schema.properties.spec.required | index("image")' >/dev/null || {
  echo "spec.image must be required"
  exit 1
}
printf '%s' "$CRD_JSON" | jq -e '.spec.versions[] | select(.name=="v1alpha1") | .schema.openAPIV3Schema.properties.spec.required | index("replicas")' >/dev/null || {
  echo "spec.replicas must be required"
  exit 1
}

echo "CRD contract is repaired"
