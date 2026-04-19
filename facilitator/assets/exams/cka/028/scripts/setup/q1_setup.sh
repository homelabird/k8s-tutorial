#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="stateful-lab"

kubectl delete pod dns-debug -n "${NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true
kubectl delete statefulset web -n "${NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true
kubectl delete service web-svc -n "${NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true
kubectl delete pvc -n "${NAMESPACE}" -l app=web --ignore-not-found >/dev/null 2>&1 || true
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f - >/dev/null

cat <<'EOF_SERVICE' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: Service
metadata:
  name: web-svc
  namespace: stateful-lab
spec:
  clusterIP: None
  selector:
    app: legacy-web
  ports:
    - name: http
      port: 80
      targetPort: 80
EOF_SERVICE

cat <<'EOF_STS' | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
  namespace: stateful-lab
spec:
  serviceName: web-svc
  replicas: 2
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
        - name: web
          image: nginx:1.25.3
          ports:
            - containerPort: 80
          volumeMounts:
            - name: www-data
              mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
    - metadata:
        name: www-data
        labels:
          app: web
      spec:
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 1Gi
EOF_STS

cat <<'EOF_DNS' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: Pod
metadata:
  name: dns-debug
  namespace: stateful-lab
spec:
  containers:
    - name: dns-debug
      image: busybox:1.36
      command:
        - sh
        - -c
        - sleep 3600
EOF_DNS
