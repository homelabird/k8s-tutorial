## Question 2601: ConfigMap and Secret envFrom diagnostics

Repair the envFrom diagnostics brief and export both the repaired manifest and a plain-text checklist.

```bash
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: envfrom-diagnostics-brief
  namespace: envfrom-lab
data:
  targetDeployment: env-bundle
  deploymentInventory: kubectl get deployment env-bundle -n envfrom-lab -o wide
  configMapEnvFromCheck: kubectl get deployment env-bundle -n envfrom-lab -o jsonpath='{.spec.template.spec.containers[0].envFrom[0].configMapRef.name}'
  secretEnvFromCheck: kubectl get deployment env-bundle -n envfrom-lab -o jsonpath='{.spec.template.spec.containers[0].envFrom[1].secretRef.name}'
  prefixCheck: kubectl get deployment env-bundle -n envfrom-lab -o jsonpath='{.spec.template.spec.containers[0].envFrom[1].prefix}'
  containerNameCheck: kubectl get deployment env-bundle -n envfrom-lab -o jsonpath='{.spec.template.spec.containers[0].name}'
  imageCheck: kubectl get deployment env-bundle -n envfrom-lab -o jsonpath='{.spec.template.spec.containers[0].image}'
  eventCheck: kubectl get events -n envfrom-lab --sort-by=.lastTimestamp
  safeManifestNote: confirm envFrom source order, secret prefix, and container name before changing the Deployment manifest
EOF_BRIEF

mkdir -p /tmp/exam/q2601
cat <<'EOF_CHECKLIST' > /tmp/exam/q2601/envfrom-diagnostics-checklist.txt
Deployment Inventory
- kubectl get deployment env-bundle -n envfrom-lab -o wide
- kubectl get deployment env-bundle -n envfrom-lab -o jsonpath='{.spec.template.spec.containers[0].name}'

EnvFrom Checks
- kubectl get deployment env-bundle -n envfrom-lab -o jsonpath='{.spec.template.spec.containers[0].envFrom[0].configMapRef.name}'
- kubectl get deployment env-bundle -n envfrom-lab -o jsonpath='{.spec.template.spec.containers[0].envFrom[1].secretRef.name}'
- kubectl get deployment env-bundle -n envfrom-lab -o jsonpath='{.spec.template.spec.containers[0].envFrom[1].prefix}'
- kubectl get deployment env-bundle -n envfrom-lab -o jsonpath='{.spec.template.spec.containers[0].image}'
- kubectl get events -n envfrom-lab --sort-by=.lastTimestamp

Safe Manifest Review
- kubectl get deployment env-bundle -n envfrom-lab -o yaml
- confirm envFrom source order, secret prefix, and container name before changing the Deployment manifest
EOF_CHECKLIST

kubectl get configmap envfrom-diagnostics-brief -n envfrom-lab -o yaml > /tmp/exam/q2601/envfrom-diagnostics-brief.yaml
```

Expected checks:

- `envfrom-diagnostics-brief` contains the intended Deployment target, exact envFrom ConfigMap and Secret source inspection commands, event evidence, and safe manifest guidance
- `/tmp/exam/q2601/envfrom-diagnostics-checklist.txt` contains the required sections and exact envFrom troubleshooting commands
- `/tmp/exam/q2601/envfrom-diagnostics-brief.yaml` exports the repaired manifest
- stale unsafe actions such as restarting the Deployment, deleting pods, or patching the live ConfigMap, Secret, or Deployment are removed
