#!/bin/bash
set -euo pipefail

NAMESPACE="triage-lab"
DEPLOYMENT="ops-api"
OUTPUT_DIR="/tmp/exam/q402"
METRICS_SERVER_URL="https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.7.2/components.yaml"

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl delete deployment "$DEPLOYMENT" -n "$NAMESPACE" --ignore-not-found=true >/dev/null 2>&1 || true
mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR/log-agent-previous.log" "$OUTPUT_DIR/ops-api-top.txt"

if ! kubectl get deployment metrics-server -n kube-system >/dev/null 2>&1; then
  kubectl apply -f "$METRICS_SERVER_URL" >/dev/null
fi
if ! kubectl get deployment metrics-server -n kube-system -o jsonpath='{.spec.template.spec.containers[0].args}' 2>/dev/null | grep -q -- '--kubelet-insecure-tls'; then
  kubectl patch deployment metrics-server -n kube-system --type=json     -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]' >/dev/null
fi
kubectl rollout status deployment/metrics-server -n kube-system --timeout=180s >/dev/null

cat <<'EOF_DEPLOY' | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ops-api
  namespace: triage-lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ops-api
  template:
    metadata:
      labels:
        app: ops-api
    spec:
      volumes:
      - name: ops-logs
        emptyDir: {}
      containers:
      - name: api
        image: nginx:1.25.5
        ports:
        - containerPort: 8080
        resources:
          requests:
            cpu: 50m
            memory: 32Mi
          limits:
            cpu: 100m
            memory: 64Mi
        livenessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 3
          periodSeconds: 3
      - name: log-agent
        image: busybox:1.36
        command:
        - sh
        - -c
        - |
          if [ "${LOG_TARGET:-}" != "/var/log/ops/app.log" ]; then
            echo "FATAL: log target ${LOG_TARGET:-unset} not found"
            exit 1
          fi
          mkdir -p "$(dirname "$LOG_TARGET")"
          touch "$LOG_TARGET"
          tail -f "$LOG_TARGET"
        env:
        - name: LOG_TARGET
          value: /var/log/missing.log
        volumeMounts:
        - name: ops-logs
          mountPath: /var/log/ops
EOF_DEPLOY

exit 0
