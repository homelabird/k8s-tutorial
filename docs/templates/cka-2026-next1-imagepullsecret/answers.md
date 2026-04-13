## Question 2001: ServiceAccount imagePullSecrets and private registry diagnostics

Repair the registry-auth diagnostics brief and export both the repaired manifest and a plain-text checklist.

```bash
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: pull-auth-diagnostics-brief
  namespace: registry-auth-lab
data:
  targetDeployment: private-api
  deploymentInventory: kubectl get deployment private-api -n registry-auth-lab -o wide
  serviceAccountCheck: kubectl get deployment private-api -n registry-auth-lab -o jsonpath='{.spec.template.spec.serviceAccountName}'
  imagePullSecretsCheck: kubectl get deployment private-api -n registry-auth-lab -o jsonpath='{.spec.template.spec.imagePullSecrets[*].name}'
  imageReferenceCheck: kubectl get deployment private-api -n registry-auth-lab -o jsonpath='{.spec.template.spec.containers[0].image}'
  secretTypeCheck: kubectl get secret regcred -n registry-auth-lab -o jsonpath='{.type}'
  serviceAccountSecretCheck: kubectl get serviceaccount puller -n registry-auth-lab -o jsonpath='{.imagePullSecrets[*].name}'
  eventCheck: kubectl get events -n registry-auth-lab --sort-by=.lastTimestamp
  safeManifestNote: confirm imagePullSecrets, ServiceAccount wiring, secret type, and image reference before changing the Deployment manifest
EOF_BRIEF

mkdir -p /tmp/exam/q2001
cat <<'EOF_CHECKLIST' > /tmp/exam/q2001/pull-auth-diagnostics-checklist.txt
Deployment Inventory
- kubectl get deployment private-api -n registry-auth-lab -o wide

Pull Secret Checks
- kubectl get deployment private-api -n registry-auth-lab -o jsonpath='{.spec.template.spec.serviceAccountName}'
- kubectl get deployment private-api -n registry-auth-lab -o jsonpath='{.spec.template.spec.imagePullSecrets[*].name}'
- kubectl get deployment private-api -n registry-auth-lab -o jsonpath='{.spec.template.spec.containers[0].image}'
- kubectl get secret regcred -n registry-auth-lab -o jsonpath='{.type}'
- kubectl get serviceaccount puller -n registry-auth-lab -o jsonpath='{.imagePullSecrets[*].name}'
- kubectl get events -n registry-auth-lab --sort-by=.lastTimestamp

Safe Manifest Review
- kubectl get deployment private-api -n registry-auth-lab -o yaml
- confirm imagePullSecrets, ServiceAccount wiring, secret type, and image reference before changing the Deployment manifest
EOF_CHECKLIST

kubectl get configmap pull-auth-diagnostics-brief -n registry-auth-lab -o yaml > /tmp/exam/q2001/pull-auth-diagnostics-brief.yaml
```

Expected checks:

- `pull-auth-diagnostics-brief` contains the intended Deployment target, exact ServiceAccount and imagePullSecrets inspection commands, secret-type evidence, event visibility, and safe manifest guidance
- `/tmp/exam/q2001/pull-auth-diagnostics-checklist.txt` contains the required sections and exact deployment inventory and registry-auth troubleshooting commands
- `/tmp/exam/q2001/pull-auth-diagnostics-brief.yaml` exports the repaired manifest
- stale unsafe actions such as restarting the Deployment, deleting pods, or patching the live ServiceAccount and Deployment are removed
