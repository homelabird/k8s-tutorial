# Answers: Downward API env and metadata diagnostics

## Question 5001

Repair `meta-diagnostics-brief` in namespace `downwardapi-lab` so it documents the exact Downward API env wiring used by deployment `meta-api`, then export the repaired ConfigMap manifest and a plain-text checklist.

Expected repaired fields:

- `targetDeployment: meta-api`
- `deploymentInventory: kubectl get deployment meta-api -n downwardapi-lab -o wide`
- `envNameCheck: kubectl get deployment meta-api -n downwardapi-lab -o jsonpath='{.spec.template.spec.containers[0].env[0].name}'`
- `fieldPathCheck: kubectl get deployment meta-api -n downwardapi-lab -o jsonpath='{.spec.template.spec.containers[0].env[0].valueFrom.fieldRef.fieldPath}'`
- `namespaceFieldCheck: kubectl get deployment meta-api -n downwardapi-lab -o jsonpath='{.spec.template.spec.containers[0].env[1].valueFrom.fieldRef.fieldPath}'`
- `containerNameCheck: kubectl get deployment meta-api -n downwardapi-lab -o jsonpath='{.spec.template.spec.containers[0].name}'`
- `imageCheck: kubectl get deployment meta-api -n downwardapi-lab -o jsonpath='{.spec.template.spec.containers[0].image}'`
- `eventCheck: kubectl get events -n downwardapi-lab --sort-by=.lastTimestamp`
- `safeManifestNote: confirm downward API fieldRef paths and target env names before changing workload manifests or forcing pod recreation`

Expected checklist sections and representative lines:

### Deployment Inventory

- `kubectl get deployment meta-api -n downwardapi-lab -o wide`
- `kubectl get deployment meta-api -n downwardapi-lab -o jsonpath='{.spec.template.spec.containers[0].env[0].name}'`

### Downward API Checks

- `kubectl get deployment meta-api -n downwardapi-lab -o jsonpath='{.spec.template.spec.containers[0].env[0].valueFrom.fieldRef.fieldPath}'`
- `kubectl get deployment meta-api -n downwardapi-lab -o jsonpath='{.spec.template.spec.containers[0].env[1].valueFrom.fieldRef.fieldPath}'`
- `kubectl get deployment meta-api -n downwardapi-lab -o jsonpath='{.spec.template.spec.containers[0].name}'`
- `kubectl get deployment meta-api -n downwardapi-lab -o jsonpath='{.spec.template.spec.containers[0].image}'`
- `kubectl get events -n downwardapi-lab --sort-by=.lastTimestamp`

### Safe Manifest Review

- `kubectl get deployment meta-api -n downwardapi-lab -o yaml`
- export `/tmp/exam/q1/meta-diagnostics-brief.yaml`
- verify the note about confirming Downward API field paths and env names before changing manifests or forcing pod recreation

Unsafe actions for this drill:

- `kubectl delete pod -n downwardapi-lab -l app=meta-api`
- `kubectl rollout restart deployment meta-api -n downwardapi-lab`
- `kubectl patch deployment meta-api -n downwardapi-lab ...`
- direct edits to running pod env values
