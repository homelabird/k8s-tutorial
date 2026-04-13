## Question 1701: Pod securityContext and fsGroup diagnostics

Repair the security diagnostics brief and export both the repaired manifest and a plain-text checklist.

```bash
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: securitycontext-diagnostics-brief
  namespace: securitycontext-lab
data:
  targetDeployment: secure-api
  deploymentInventory: kubectl get deployment secure-api -n securitycontext-lab -o wide
  runAsUserCheck: kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.securityContext.runAsUser}'
  fsGroupCheck: kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.securityContext.fsGroup}'
  seccompCheck: kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.containers[0].securityContext.seccompProfile.type}'
  allowPrivilegeEscalationCheck: kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.containers[0].securityContext.allowPrivilegeEscalation}'
  capabilitiesDropCheck: kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.containers[0].securityContext.capabilities.drop[0]}'
  mountPathCheck: kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'
  eventCheck: kubectl get events -n securitycontext-lab --sort-by=.lastTimestamp
  safeManifestNote: confirm runAsUser, fsGroup, seccomp, capability drop, and mount path before changing the Deployment manifest
EOF_BRIEF

mkdir -p /tmp/exam/q1701
cat <<'EOF_CHECKLIST' > /tmp/exam/q1701/securitycontext-diagnostics-checklist.txt
Deployment Inventory
- kubectl get deployment secure-api -n securitycontext-lab -o wide
- kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.securityContext.runAsUser}'

Security Context Checks
- kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.securityContext.fsGroup}'
- kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.containers[0].securityContext.seccompProfile.type}'
- kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.containers[0].securityContext.allowPrivilegeEscalation}'
- kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.containers[0].securityContext.capabilities.drop[0]}'
- kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'
- kubectl get events -n securitycontext-lab --sort-by=.lastTimestamp

Safe Manifest Review
- kubectl get deployment secure-api -n securitycontext-lab -o yaml
- confirm runAsUser, fsGroup, seccomp, capability drop, and mount path before changing the Deployment manifest
EOF_CHECKLIST

kubectl get configmap securitycontext-diagnostics-brief -n securitycontext-lab -o yaml > /tmp/exam/q1701/securitycontext-diagnostics-brief.yaml
```

Expected checks:

- `securitycontext-diagnostics-brief` contains the intended Deployment target, exact securityContext inspection commands, events check, and safe manifest guidance
- `/tmp/exam/q1701/securitycontext-diagnostics-checklist.txt` contains the required sections and exact deployment inventory and workload security troubleshooting commands
- `/tmp/exam/q1701/securitycontext-diagnostics-brief.yaml` exports the repaired manifest
- stale unsafe actions such as restarting the Deployment, deleting pods, or patching the live securityContext fields are removed
