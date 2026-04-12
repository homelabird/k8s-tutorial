## Question 1: DaemonSet rollout and node coverage diagnostics

Repair the DaemonSet diagnostics brief and export both the repaired manifest and a plain-text checklist.

```bash
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: daemonset-rollout-brief
  namespace: daemonset-lab
data:
  targetDaemonSet: log-agent
  daemonSetInventory: kubectl get daemonset log-agent -n daemonset-lab -o wide
  rolloutStatusCheck: kubectl rollout status daemonset/log-agent -n daemonset-lab --timeout=180s
  nodeInventory: kubectl get nodes -o wide
  nodeCoverageCheck: kubectl get pods -n daemonset-lab -l app=log-agent -o wide
  updateStrategyCheck: kubectl get daemonset log-agent -n daemonset-lab -o jsonpath='{.spec.updateStrategy.type}'
  safeManifestNote: "confirm desiredNumberScheduled matches running pods before changing DaemonSet manifests"
EOF_BRIEF

mkdir -p /tmp/exam/q1001
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/daemonset-rollout-checklist.txt
DaemonSet Inventory
- kubectl get daemonset log-agent -n daemonset-lab -o wide
- kubectl rollout status daemonset/log-agent -n daemonset-lab --timeout=180s

Node Coverage
- kubectl get nodes -o wide
- kubectl get pods -n daemonset-lab -l app=log-agent -o wide

Safe Rollout Review
- kubectl get daemonset log-agent -n daemonset-lab -o jsonpath='{.spec.updateStrategy.type}'
- confirm desiredNumberScheduled matches running pods before changing DaemonSet manifests
EOF_CHECKLIST

kubectl get configmap daemonset-rollout-brief -n daemonset-lab -o yaml > /tmp/exam/q1/daemonset-rollout-brief.yaml
```

Expected checks:

- `daemonset-rollout-brief` contains the intended DaemonSet target, rollout status command, node coverage commands, and safe manifest note
- `/tmp/exam/q1/daemonset-rollout-checklist.txt` contains the required sections and exact DaemonSet, node coverage, and rollout review commands
- `/tmp/exam/q1/daemonset-rollout-brief.yaml` exports the repaired manifest
- stale unsafe actions such as deleting the DaemonSet, scaling it, or cordoning nodes are removed
