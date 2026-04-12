#!/bin/bash
set -euo pipefail

NAMESPACE="gateway-lab"
GATEWAY_CLASS="cka-014-gc"
GATEWAY="main-gateway"
ROUTE="app-routes"
OUTPUT_DIR="/tmp/exam/q401"

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl delete httproute "$ROUTE" -n "$NAMESPACE" --ignore-not-found=true >/dev/null 2>&1 || true
kubectl delete gateway "$GATEWAY" -n "$NAMESPACE" --ignore-not-found=true >/dev/null 2>&1 || true
kubectl delete gatewayclass "$GATEWAY_CLASS" --ignore-not-found=true >/dev/null 2>&1 || true
kubectl delete gatewayclass legacy-gc --ignore-not-found=true >/dev/null 2>&1 || true
kubectl delete deployment app1 app2 -n "$NAMESPACE" --ignore-not-found=true >/dev/null 2>&1 || true
kubectl delete service app1-svc app2-svc -n "$NAMESPACE" --ignore-not-found=true >/dev/null 2>&1 || true
mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR/app-routes.yaml"

if ! kubectl get crd gatewayclasses.gateway.networking.k8s.io >/dev/null 2>&1; then
  kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/standard-install.yaml >/dev/null
fi
kubectl wait --for=condition=established --timeout=120s crd/gatewayclasses.gateway.networking.k8s.io >/dev/null
kubectl wait --for=condition=established --timeout=120s crd/gateways.gateway.networking.k8s.io >/dev/null
kubectl wait --for=condition=established --timeout=120s crd/httproutes.gateway.networking.k8s.io >/dev/null

cat <<'EOF_BASE' | kubectl apply -f - >/dev/null
apiVersion: gateway.networking.k8s.io/v1beta1
kind: GatewayClass
metadata:
  name: legacy-gc
spec:
  controllerName: example.com/legacy-controller
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app1
  namespace: gateway-lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app1
  template:
    metadata:
      labels:
        app: app1
    spec:
      containers:
      - name: web
        image: nginx:1.25.5
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: app1-svc
  namespace: gateway-lab
spec:
  selector:
    app: app1
  ports:
  - port: 8080
    targetPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app2
  namespace: gateway-lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app2
  template:
    metadata:
      labels:
        app: app2
    spec:
      containers:
      - name: web
        image: nginx:1.25.5
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: app2-svc
  namespace: gateway-lab
spec:
  selector:
    app: app2
  ports:
  - port: 8080
    targetPort: 80
---
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: main-gateway
  namespace: gateway-lab
spec:
  gatewayClassName: legacy-gc
  listeners:
  - name: http
    port: 8081
    protocol: HTTP
---
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: app-routes
  namespace: gateway-lab
spec:
  hostnames:
  - apps.example.local
  parentRefs:
  - name: legacy-gateway
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /app1
    backendRefs:
    - name: app2-svc
      port: 8080
  - matches:
    - path:
        type: PathPrefix
        value: /legacy
    backendRefs:
    - name: app1-svc
      port: 8080
EOF_BASE

kubectl rollout status deployment/app1 -n "$NAMESPACE" --timeout=180s >/dev/null
kubectl rollout status deployment/app2 -n "$NAMESPACE" --timeout=180s >/dev/null
