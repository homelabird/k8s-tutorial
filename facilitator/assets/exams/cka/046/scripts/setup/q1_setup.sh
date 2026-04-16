#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="subpath-lab"
OUTPUT_DIR="/tmp/exam/q1"

kubectl delete namespace "${NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true
kubectl create namespace "${NAMESPACE}" >/dev/null
mkdir -p "${OUTPUT_DIR}"

cat <<'EOF_CONFIGMAP' | kubectl apply -n "${NAMESPACE}" -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  app.conf: |
    mode=production
    feature=stable
EOF_CONFIGMAP

cat <<'EOF_DEPLOYMENT' | kubectl apply -n "${NAMESPACE}" -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: subpath-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: subpath-api
  template:
    metadata:
      labels:
        app: subpath-api
    spec:
      volumes:
        - name: app-config
          configMap:
            name: app-config
            items:
              - key: app.conf
                path: config/app.conf
      containers:
        - name: api
          image: nginx:1.25.3
          volumeMounts:
            - name: app-config
              mountPath: /etc/app/app.conf
              subPath: config/app.conf
              readOnly: true
EOF_DEPLOYMENT

cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: subpath-diagnostics-brief
  namespace: subpath-lab
data:
  targetDeployment: worker-api
  deploymentInventory: kubectl get pods -n subpath-lab
  configMapNameCheck: kubectl patch configmap app-config -n subpath-lab --type merge -p '{"data":{"mode":"debug"}}'
  itemPathCheck: kubectl rollout restart deployment/subpath-api -n subpath-lab
  mountPathCheck: kubectl get deployment subpath-api -n subpath-lab -o jsonpath='{.spec.template.spec.containers[0].image}'
  subPathCheck: kubectl delete pod -n subpath-lab -l app=subpath-api
  readOnlyCheck: kubectl patch deployment subpath-api -n subpath-lab --type merge -p '{"spec":{"template":{"spec":{"containers":[{"name":"api","volumeMounts":[{"name":"app-config","mountPath":"/srv/app.conf"}]}]}}}}'
  containerNameCheck: kubectl get configmap app-config -n subpath-lab -o yaml
  imageCheck: kubectl get deployment subpath-api -n subpath-lab -o jsonpath='{.spec.template.spec.containers[0].name}'
  eventCheck: kubectl get configmap -n subpath-lab
  safeManifestNote: restart the deployment and patch the live ConfigMap until the mounted file looks right
EOF_BRIEF

rm -f "${OUTPUT_DIR}/subpath-diagnostics-brief.yaml" "${OUTPUT_DIR}/subpath-diagnostics-checklist.txt"
