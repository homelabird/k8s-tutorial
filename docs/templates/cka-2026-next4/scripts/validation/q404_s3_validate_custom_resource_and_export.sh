#!/bin/bash
set -euo pipefail

NAMESPACE="operator-lab"
RESOURCE_NAME="sample-widget"
EXPORT_FILE="/tmp/exam/q404/widget-crd.yaml"

kubectl get widget "$RESOURCE_NAME" -n "$NAMESPACE" >/dev/null 2>&1 || { echo "sample-widget custom resource not found"; exit 1; }

API_VERSION="$(kubectl get widget "$RESOURCE_NAME" -n "$NAMESPACE" -o jsonpath='{.apiVersion}')"
IMAGE="$(kubectl get widget "$RESOURCE_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.image}')"
REPLICAS="$(kubectl get widget "$RESOURCE_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')"

[ "$API_VERSION" = "training.cka.io/v1alpha1" ] || { echo "sample-widget apiVersion must be training.cka.io/v1alpha1"; exit 1; }
[ "$IMAGE" = "nginx:1.25.5" ] || { echo "sample-widget image must be nginx:1.25.5"; exit 1; }
[ "$REPLICAS" = "2" ] || { echo "sample-widget replicas must be 2"; exit 1; }
[ -f "$EXPORT_FILE" ] || { echo "Expected CRD export at $EXPORT_FILE"; exit 1; }
grep -Fq 'name: widgets.training.cka.io' "$EXPORT_FILE" || { echo "Exported CRD manifest must contain widgets.training.cka.io"; exit 1; }
grep -Fq 'group: training.cka.io' "$EXPORT_FILE" || { echo "Exported CRD manifest must contain training.cka.io"; exit 1; }
grep -Fq 'kind: Widget' "$EXPORT_FILE" || { echo "Exported CRD manifest must contain kind Widget"; exit 1; }

echo "Custom resource contract and CRD export are repaired"
