## Question 901: StatefulSet identity and headless service diagnostics

Repair the StatefulSet diagnostics brief and export both the repaired manifest and a plain-text checklist.

```bash
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: stateful-identity-brief
  namespace: stateful-lab
data:
  targetStatefulSet: web
  headlessService: web-svc
  statefulSetInventory: kubectl get statefulset web -n stateful-lab -o wide
  serviceInspection: kubectl get svc web-svc -n stateful-lab -o yaml
  podInventory: kubectl get pods -n stateful-lab -l app=web -o wide
  ordinalDnsCheck: kubectl exec -n stateful-lab dns-debug -- nslookup web-0.web-svc.stateful-lab.svc.cluster.local
  pvcInventory: kubectl get pvc -n stateful-lab
  safeManifestNote: confirm serviceName: web-svc and stable pod ordinals before changing manifests
EOF_BRIEF

mkdir -p /tmp/exam/q901
cat <<'EOF_CHECKLIST' > /tmp/exam/q901/stateful-identity-checklist.txt
StatefulSet Inventory
- kubectl get statefulset web -n stateful-lab -o wide
- kubectl get pods -n stateful-lab -l app=web -o wide

Stable Network Identity
- kubectl get svc web-svc -n stateful-lab -o yaml
- kubectl exec -n stateful-lab dns-debug -- nslookup web-0.web-svc.stateful-lab.svc.cluster.local

Safe Manifest Review
- kubectl get pvc -n stateful-lab
- confirm serviceName: web-svc and stable pod ordinals before changing manifests
EOF_CHECKLIST

kubectl get configmap stateful-identity-brief -n stateful-lab -o yaml > /tmp/exam/q901/stateful-identity-brief.yaml
```

Expected checks:

- `stateful-identity-brief` contains the intended StatefulSet target, headless Service inspection commands, pod inventory, ordinal DNS guidance, and safe manifest note
- `/tmp/exam/q901/stateful-identity-checklist.txt` contains the required sections and exact StatefulSet, headless Service, DNS, and PVC troubleshooting commands
- `/tmp/exam/q901/stateful-identity-brief.yaml` exports the repaired manifest
- stale unsafe actions such as deleting the StatefulSet, deleting PVCs, or converting the Service into a NodePort are removed
