#!/bin/bash
set -euo pipefail

NAMESPACE="operator-lab"
CRD_NAME="widgets.training.cka.io"
DEPLOYMENT="widget-operator"
OUTPUT_DIR="/tmp/exam/q1"

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl delete deployment "$DEPLOYMENT" -n "$NAMESPACE" --ignore-not-found=true >/dev/null 2>&1 || true
kubectl delete widget sample-widget -n "$NAMESPACE" --ignore-not-found=true >/dev/null 2>&1 || true
kubectl delete crd "$CRD_NAME" --ignore-not-found=true >/dev/null 2>&1 || true
mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR/widget-crd.yaml"

cat <<'EOF_CRD' | kubectl apply -f - >/dev/null
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: widgets.training.cka.io
spec:
  group: training.cka.io
  scope: Namespaced
  names:
    plural: widgets
    singular: widget
    kind: Widget
  versions:
  - name: v1alpha1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            required:
            - image
            properties:
              image:
                type: string
              replicas:
                type: string
EOF_CRD

kubectl wait --for=condition=established --timeout=120s "crd/${CRD_NAME}" >/dev/null

cat <<'EOF_DEPLOY' | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: widget-operator
  namespace: operator-lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: widget-operator
  template:
    metadata:
      labels:
        app: widget-operator
    spec:
      containers:
      - name: manager
        image: busybox:1.36
        command:
        - sh
        - -c
        - |
          echo "operator exiting"
          exit 1
EOF_DEPLOY

cat <<'EOF_CR' | kubectl apply -f - >/dev/null
apiVersion: training.cka.io/v1alpha1
kind: Widget
metadata:
  name: sample-widget
  namespace: operator-lab
spec:
  image: nginx:1.25.3
  replicas: "1"
EOF_CR

exit 0
