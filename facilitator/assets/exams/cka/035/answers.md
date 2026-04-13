## Question 1: ServiceAccount identity and projected token diagnostics

Repair the identity diagnostics brief and export both the repaired manifest and a plain-text checklist.

```bash
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: identity-diagnostics-brief
  namespace: identity-lab
data:
  targetDeployment: metrics-api
  deploymentInventory: kubectl get deployment metrics-api -n identity-lab -o wide
  serviceAccountCheck: kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.serviceAccountName}'
  automountCheck: kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.automountServiceAccountToken}'
  projectedTokenPathCheck: kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[0].serviceAccountToken.path}'
  projectedAudienceCheck: kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[0].serviceAccountToken.audience}'
  mountPathCheck: kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'
  eventCheck: kubectl get events -n identity-lab --sort-by=.lastTimestamp
  safeManifestNote: confirm serviceAccountName, projected token audience, and mount path before changing the Deployment manifest
EOF_BRIEF

mkdir -p /tmp/exam/q1
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/identity-diagnostics-checklist.txt
Deployment Inventory
- kubectl get deployment metrics-api -n identity-lab -o wide
- kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.serviceAccountName}'

Identity Checks
- kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.automountServiceAccountToken}'
- kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[0].serviceAccountToken.path}'
- kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[0].serviceAccountToken.audience}'
- kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'
- kubectl get events -n identity-lab --sort-by=.lastTimestamp

Safe Manifest Review
- kubectl get deployment metrics-api -n identity-lab -o yaml
- confirm serviceAccountName, projected token audience, and mount path before changing the Deployment manifest
EOF_CHECKLIST

kubectl get configmap identity-diagnostics-brief -n identity-lab -o yaml > /tmp/exam/q1/identity-diagnostics-brief.yaml
```

Expected checks:

- `identity-diagnostics-brief` contains the intended Deployment target, exact ServiceAccount and projected token inspection commands, events check, and safe manifest guidance
- `/tmp/exam/q1/identity-diagnostics-checklist.txt` contains the required sections and exact deployment inventory and workload identity troubleshooting commands
- `/tmp/exam/q1/identity-diagnostics-brief.yaml` exports the repaired manifest
- stale unsafe actions such as restarting the Deployment, deleting pods, or patching the live ServiceAccount fields are removed
