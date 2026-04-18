# Answers: Taints, tolerations, and NoExecute eviction diagnostics

## Question 5101

Repair `taint-diagnostics-brief` in namespace `taints-lab` so it documents the exact taint-toleration wiring used by deployment `taint-api`, then export the repaired ConfigMap manifest and a plain-text checklist.

Expected repaired fields:

- `targetDeployment: taint-api`
- `deploymentInventory: kubectl get deployment taint-api -n taints-lab -o wide`
- `tolerationKeyCheck: kubectl get deployment taint-api -n taints-lab -o jsonpath='{.spec.template.spec.tolerations[0].key}'`
- `tolerationEffectCheck: kubectl get deployment taint-api -n taints-lab -o jsonpath='{.spec.template.spec.tolerations[0].effect}'`
- `tolerationOperatorCheck: kubectl get deployment taint-api -n taints-lab -o jsonpath='{.spec.template.spec.tolerations[0].operator}'`
- `tolerationSecondsCheck: kubectl get deployment taint-api -n taints-lab -o jsonpath='{.spec.template.spec.tolerations[0].tolerationSeconds}'`
- `nodeSelectorCheck: kubectl get deployment taint-api -n taints-lab -o jsonpath='{.spec.template.spec.nodeSelector.workload}'`
- `eventCheck: kubectl get events -n taints-lab --sort-by=.lastTimestamp`
- `safeManifestNote: confirm taint effect, toleration seconds, and node selector before changing workload manifests or mutating node taints`

Expected checklist sections and representative lines:

### Deployment Inventory

- `kubectl get deployment taint-api -n taints-lab -o wide`
- `kubectl get deployment taint-api -n taints-lab -o jsonpath='{.spec.template.spec.tolerations[0].key}'`

### Toleration Checks

- `kubectl get deployment taint-api -n taints-lab -o jsonpath='{.spec.template.spec.tolerations[0].effect}'`
- `kubectl get deployment taint-api -n taints-lab -o jsonpath='{.spec.template.spec.tolerations[0].operator}'`
- `kubectl get deployment taint-api -n taints-lab -o jsonpath='{.spec.template.spec.tolerations[0].tolerationSeconds}'`
- `kubectl get deployment taint-api -n taints-lab -o jsonpath='{.spec.template.spec.nodeSelector.workload}'`
- `kubectl get events -n taints-lab --sort-by=.lastTimestamp`

### Safe Manifest Review

- `kubectl get deployment taint-api -n taints-lab -o yaml`
- export `/tmp/exam/q1/taint-diagnostics-brief.yaml`
- verify the note about confirming taint effect, toleration seconds, and node selector before changing manifests or mutating node taints

Unsafe actions for this drill:

- `kubectl drain`
- `kubectl delete pod -n taints-lab -l app=taint-api`
- `kubectl rollout restart deployment taint-api -n taints-lab`
- patching live node taints during the drill
