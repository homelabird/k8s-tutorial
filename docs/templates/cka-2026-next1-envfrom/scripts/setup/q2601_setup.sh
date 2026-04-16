#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="envfrom-lab"
OUTPUT_DIR="/tmp/exam/q2601"

kubectl delete namespace "${NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true
kubectl create namespace "${NAMESPACE}" >/dev/null
mkdir -p "${OUTPUT_DIR}"

cat <<'EOF_CONFIGMAP' | kubectl apply -n "${NAMESPACE}" -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-env
data:
  APP_MODE: safe
  APP_REGION: ap-northeast-2
EOF_CONFIGMAP

cat <<'EOF_SECRET' | kubectl apply -n "${NAMESPACE}" -f -
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
stringData:
  TOKEN: redacted
EOF_SECRET

cat <<'EOF_DEPLOYMENT' | kubectl apply -n "${NAMESPACE}" -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: env-bundle
spec:
  replicas: 1
  selector:
    matchLabels:
      app: env-bundle
  template:
    metadata:
      labels:
        app: env-bundle
    spec:
      containers:
        - name: api
          image: nginx:1.25.3
          envFrom:
            - configMapRef:
                name: app-env
            - secretRef:
                name: app-secrets
              prefix: SEC_
EOF_DEPLOYMENT

cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: envfrom-diagnostics-brief
  namespace: envfrom-lab
data:
  targetDeployment: env-worker
  deploymentInventory: kubectl get pods -n envfrom-lab
  configMapEnvFromCheck: kubectl patch configmap app-env -n envfrom-lab --type merge -p '{"data":{"APP_MODE":"fast"}}'
  secretEnvFromCheck: kubectl rollout restart deployment/env-bundle -n envfrom-lab
  prefixCheck: kubectl get deployment env-bundle -n envfrom-lab -o jsonpath='{.spec.template.spec.containers[0].image}'
  containerNameCheck: kubectl delete pod -n envfrom-lab -l app=env-bundle
  imageCheck: kubectl patch deployment env-bundle -n envfrom-lab --type merge -p '{"spec":{"template":{"spec":{"containers":[{"name":"web","image":"busybox"}]}}}}'
  eventCheck: kubectl get configmap -n envfrom-lab
  safeManifestNote: restart the deployment and patch live envFrom sources until environment variables line up
EOF_BRIEF

rm -f "${OUTPUT_DIR}/envfrom-diagnostics-brief.yaml" "${OUTPUT_DIR}/envfrom-diagnostics-checklist.txt"
