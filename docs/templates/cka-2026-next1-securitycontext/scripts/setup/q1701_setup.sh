#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="securitycontext-lab"
OUTPUT_DIR="/tmp/exam/q1701"

kubectl delete namespace "${NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true
kubectl create namespace "${NAMESPACE}" >/dev/null
mkdir -p "${OUTPUT_DIR}"

cat <<'EOF_DEPLOYMENT' | kubectl apply -n "${NAMESPACE}" -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: secure-api
  template:
    metadata:
      labels:
        app: secure-api
    spec:
      securityContext:
        runAsUser: 1000
        fsGroup: 2000
      volumes:
        - name: workdir
          emptyDir: {}
      containers:
        - name: api
          image: nginx:1.25.3
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop:
                - ALL
            seccompProfile:
              type: RuntimeDefault
          volumeMounts:
            - name: workdir
              mountPath: /var/lib/app
EOF_DEPLOYMENT

cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: securitycontext-diagnostics-brief
  namespace: securitycontext-lab
data:
  targetDeployment: edge-api
  deploymentInventory: kubectl get pods -n securitycontext-lab
  runAsUserCheck: kubectl rollout restart deployment/secure-api -n securitycontext-lab
  fsGroupCheck: kubectl patch deployment secure-api -n securitycontext-lab --type merge -p '{"spec":{"template":{"spec":{"securityContext":{"fsGroup":3000}}}}}'
  seccompCheck: kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.containers[0].image}'
  allowPrivilegeEscalationCheck: kubectl delete pod -n securitycontext-lab -l app=secure-api
  capabilitiesDropCheck: kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.containers[0].ports[0].containerPort}'
  mountPathCheck: kubectl get pvc -n securitycontext-lab
  eventCheck: kubectl get pods -n securitycontext-lab
  safeManifestNote: restart the deployment and patch the security context until the pod is admitted
EOF_BRIEF

rm -f "${OUTPUT_DIR}/securitycontext-diagnostics-brief.yaml" "${OUTPUT_DIR}/securitycontext-diagnostics-checklist.txt"
