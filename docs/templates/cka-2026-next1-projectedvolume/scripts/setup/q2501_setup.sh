#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="projectedvolume-lab"
OUTPUT_DIR="/tmp/exam/q2501"

kubectl delete namespace "${NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true
kubectl create namespace "${NAMESPACE}" >/dev/null
mkdir -p "${OUTPUT_DIR}"

cat <<'EOF_CONFIGMAP' | kubectl apply -n "${NAMESPACE}" -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  app.yaml: |
    mode: safe
    featureFlag: enabled
EOF_CONFIGMAP

cat <<'EOF_SECRET' | kubectl apply -n "${NAMESPACE}" -f -
apiVersion: v1
kind: Secret
metadata:
  name: api-credentials
type: Opaque
stringData:
  token: super-secret-token
EOF_SECRET

cat <<'EOF_DEPLOYMENT' | kubectl apply -n "${NAMESPACE}" -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bundle-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: bundle-api
  template:
    metadata:
      labels:
        app: bundle-api
    spec:
      volumes:
        - name: projected-config
          projected:
            sources:
              - configMap:
                  name: app-config
                  items:
                    - key: app.yaml
                      path: config/app.yaml
              - secret:
                  name: api-credentials
                  items:
                    - key: token
                      path: credentials/token
      containers:
        - name: api
          image: nginx:1.25.3
          volumeMounts:
            - name: projected-config
              mountPath: /etc/bundle-config
              readOnly: true
EOF_DEPLOYMENT

cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: projected-volume-brief
  namespace: projectedvolume-lab
data:
  targetDeployment: bundle-worker
  deploymentInventory: kubectl get pods -n projectedvolume-lab
  configMapNameCheck: kubectl patch configmap app-config -n projectedvolume-lab --type merge -p '{"data":{"mode":"fast"}}'
  configMapItemPathCheck: kubectl rollout restart deployment/bundle-api -n projectedvolume-lab
  secretNameCheck: kubectl get deployment bundle-api -n projectedvolume-lab -o jsonpath='{.spec.template.spec.containers[0].image}'
  secretItemPathCheck: kubectl delete pod -n projectedvolume-lab -l app=bundle-api
  mountPathCheck: kubectl patch deployment bundle-api -n projectedvolume-lab --type merge -p '{"spec":{"template":{"spec":{"containers":[{"name":"api","volumeMounts":[{"name":"projected-config","mountPath":"/srv/config"}]}]}}}}'
  readOnlyCheck: kubectl get secret api-credentials -n projectedvolume-lab -o yaml
  eventCheck: kubectl get configmap -n projectedvolume-lab
  safeManifestNote: restart the deployment and patch live source objects until the projected volume looks right
EOF_BRIEF

rm -f "${OUTPUT_DIR}/projected-volume-brief.yaml" "${OUTPUT_DIR}/projected-volume-checklist.txt"
