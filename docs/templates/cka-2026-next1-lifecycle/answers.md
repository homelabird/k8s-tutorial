# Answers: Lifecycle hooks and graceful termination diagnostics

## Question 4901

Repair `lifecycle-diagnostics-brief` in namespace `lifecycle-lab` so it documents the exact graceful-termination wiring used by deployment `lifecycle-api`, then export the repaired ConfigMap manifest and a plain-text checklist.

Expected repaired fields:

- `targetDeployment: lifecycle-api`
- `deploymentInventory: kubectl get deployment lifecycle-api -n lifecycle-lab -o wide`
- `terminationGraceCheck: kubectl get deployment lifecycle-api -n lifecycle-lab -o jsonpath='{.spec.template.spec.terminationGracePeriodSeconds}'`
- `preStopTypeCheck: kubectl get deployment lifecycle-api -n lifecycle-lab -o jsonpath='{.spec.template.spec.containers[0].lifecycle.preStop.exec.command[0]}'`
- `preStopCommandCheck: kubectl get deployment lifecycle-api -n lifecycle-lab -o jsonpath='{.spec.template.spec.containers[0].lifecycle.preStop.exec.command[2]}'`
- `containerCommandCheck: kubectl get deployment lifecycle-api -n lifecycle-lab -o jsonpath='{.spec.template.spec.containers[0].command[2]}'`
- `imageCheck: kubectl get deployment lifecycle-api -n lifecycle-lab -o jsonpath='{.spec.template.spec.containers[0].image}'`
- `eventCheck: kubectl get events -n lifecycle-lab --sort-by=.lastTimestamp`
- `safeManifestNote: confirm lifecycle preStop commands and termination grace period before changing workload manifests or forcing pod deletion`

Expected checklist sections and representative lines:

### Deployment Inventory

- `kubectl get deployment lifecycle-api -n lifecycle-lab -o wide`
- `kubectl get deployment lifecycle-api -n lifecycle-lab -o jsonpath='{.spec.template.spec.terminationGracePeriodSeconds}'`

### Lifecycle Hook Checks

- `kubectl get deployment lifecycle-api -n lifecycle-lab -o jsonpath='{.spec.template.spec.containers[0].lifecycle.preStop.exec.command[0]}'`
- `kubectl get deployment lifecycle-api -n lifecycle-lab -o jsonpath='{.spec.template.spec.containers[0].lifecycle.preStop.exec.command[2]}'`
- `kubectl get deployment lifecycle-api -n lifecycle-lab -o jsonpath='{.spec.template.spec.containers[0].command[2]}'`
- `kubectl get deployment lifecycle-api -n lifecycle-lab -o jsonpath='{.spec.template.spec.containers[0].image}'`
- `kubectl get events -n lifecycle-lab --sort-by=.lastTimestamp`

### Safe Manifest Review

- `kubectl get deployment lifecycle-api -n lifecycle-lab -o yaml`
- export `/tmp/exam/q1/lifecycle-diagnostics-brief.yaml`
- verify the note about confirming `preStop` commands and termination grace period before changing manifests or forcing pod deletion

Unsafe actions for this drill:

- `kubectl delete pod -n lifecycle-lab -l app=lifecycle-api`
- `kubectl rollout restart deployment lifecycle-api -n lifecycle-lab`
- `kubectl patch deployment lifecycle-api -n lifecycle-lab ...`
- force-delete or zero-grace deletion commands
