#!/bin/bash
set -euo pipefail

NAMESPACE="autoscale-lab"
DEPLOYMENT="worker-api"
HPA="worker-api-hpa"

kubectl create namespace "$NAMESPACE" >/dev/null 2>&1 || true
kubectl delete hpa "$HPA" -n "$NAMESPACE" --ignore-not-found=true >/dev/null 2>&1 || true
kubectl delete deployment "$DEPLOYMENT" -n "$NAMESPACE" --ignore-not-found=true >/dev/null 2>&1 || true
mkdir -p /tmp/exam/q1
rm -f /tmp/exam/q1/worker-api-hpa.yaml

cat <<'EOF_DEPLOY' | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: worker-api
  namespace: autoscale-lab
spec:
  replicas: 2
  selector:
    matchLabels:
      app: worker-api
  template:
    metadata:
      labels:
        app: worker-api
    spec:
      containers:
      - name: api
        image: nginx:1.25.5
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 50m
EOF_DEPLOY

cat <<'EOF_HPA' | kubectl apply -f - >/dev/null
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: worker-api-hpa
  namespace: autoscale-lab
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: worker-api-old
  minReplicas: 1
  maxReplicas: 2
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 85
EOF_HPA

exit 0
