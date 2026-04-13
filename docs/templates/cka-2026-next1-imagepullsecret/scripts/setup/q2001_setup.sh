#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="registry-auth-lab"
OUTPUT_DIR="/tmp/exam/q2001"

kubectl delete namespace "${NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true
kubectl create namespace "${NAMESPACE}" >/dev/null
mkdir -p "${OUTPUT_DIR}"

cat <<'EOF_SECRET' | kubectl apply -n "${NAMESPACE}" -f -
apiVersion: v1
kind: Secret
metadata:
  name: regcred
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: eyJhdXRocyI6eyJyZWdpc3RyeS5leGFtcGxlLmNvbSI6eyJ1c2VybmFtZSI6ImRyaWxsIiwicGFzc3dvcmQiOiJzZWNyZXQiLCJhdXRoIjoiWkhKcGJHdzZjMlZqY21WMCJ9fX0=
EOF_SECRET

cat <<'EOF_SERVICEACCOUNT' | kubectl apply -n "${NAMESPACE}" -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: puller
imagePullSecrets:
  - name: regcred
EOF_SERVICEACCOUNT

cat <<'EOF_DEPLOYMENT' | kubectl apply -n "${NAMESPACE}" -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: private-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: private-api
  template:
    metadata:
      labels:
        app: private-api
    spec:
      serviceAccountName: puller
      imagePullSecrets:
        - name: regcred
      containers:
        - name: api
          image: registry.example.com/team/private-api:v1.2.3
EOF_DEPLOYMENT

cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: pull-auth-diagnostics-brief
  namespace: registry-auth-lab
data:
  targetDeployment: edge-api
  deploymentInventory: kubectl get pods -n registry-auth-lab
  serviceAccountCheck: kubectl patch deployment private-api -n registry-auth-lab --type merge -p '{"spec":{"template":{"spec":{"serviceAccountName":"puller"}}}}'
  imagePullSecretsCheck: kubectl set serviceaccount puller -n registry-auth-lab --image-pull-secrets=regcred
  imageReferenceCheck: kubectl rollout restart deployment/private-api -n registry-auth-lab
  secretTypeCheck: kubectl get secrets -n registry-auth-lab
  serviceAccountSecretCheck: kubectl delete pod -n registry-auth-lab -l app=private-api
  eventCheck: kubectl get deployment private-api -n registry-auth-lab
  safeManifestNote: restart the deployment and patch the service account until the image pull secret wiring looks right
EOF_BRIEF

rm -f "${OUTPUT_DIR}/pull-auth-diagnostics-brief.yaml" "${OUTPUT_DIR}/pull-auth-diagnostics-checklist.txt"
