## Question 1501: Pod anti-affinity and topology spread diagnostics

Repair the placement diagnostics brief and export both the repaired manifest and a plain-text checklist.

```bash
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: placement-diagnostics-brief
  namespace: affinity-lab
data:
  targetDeployment: api-fleet
  deploymentInventory: kubectl get deployment api-fleet -n affinity-lab -o wide
  replicaCheck: kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.replicas}'
  antiAffinityTopologyCheck: kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].topologyKey}'
  antiAffinitySelectorCheck: kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].labelSelector.matchLabels.app}'
  topologySpreadKeyCheck: kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.topologySpreadConstraints[0].topologyKey}'
  maxSkewCheck: kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.topologySpreadConstraints[0].maxSkew}'
  whenUnsatisfiableCheck: kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.topologySpreadConstraints[0].whenUnsatisfiable}'
  eventCheck: kubectl get events -n affinity-lab --sort-by=.lastTimestamp
  safeManifestNote: confirm pod anti-affinity selectors and topology spread constraints before changing the Deployment manifest
EOF_BRIEF

mkdir -p /tmp/exam/q1501
cat <<'EOF_CHECKLIST' > /tmp/exam/q1501/placement-diagnostics-checklist.txt
Deployment Inventory
- kubectl get deployment api-fleet -n affinity-lab -o wide
- kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.replicas}'

Placement Checks
- kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].topologyKey}'
- kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].labelSelector.matchLabels.app}'
- kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.topologySpreadConstraints[0].topologyKey}'
- kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.topologySpreadConstraints[0].maxSkew}'
- kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.topologySpreadConstraints[0].whenUnsatisfiable}'
- kubectl get events -n affinity-lab --sort-by=.lastTimestamp

Safe Manifest Review
- kubectl get deployment api-fleet -n affinity-lab -o yaml
- confirm pod anti-affinity selectors and topology spread constraints before changing the Deployment manifest
EOF_CHECKLIST

kubectl get configmap placement-diagnostics-brief -n affinity-lab -o yaml > /tmp/exam/q1501/placement-diagnostics-brief.yaml
```

Expected checks:

- `placement-diagnostics-brief` contains the intended Deployment target, exact anti-affinity and topology spread inspection commands, events check, and safe manifest guidance
- `/tmp/exam/q1501/placement-diagnostics-checklist.txt` contains the required sections and exact deployment inventory and placement troubleshooting commands
- `/tmp/exam/q1501/placement-diagnostics-brief.yaml` exports the repaired manifest
- stale unsafe actions such as restarting the Deployment, deleting pods, scaling replicas, or patching the live placement rules are removed
