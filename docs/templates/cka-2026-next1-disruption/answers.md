## Question 801: PodDisruptionBudget and drain planning

Repair the disruption planning brief and export both the repaired manifest and a plain-text checklist.

```bash
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: disruption-planning-brief
  namespace: disruption-lab
data:
  targetNode: kind-cluster-worker
  pdbInventory: kubectl get pdb -A
  pdbDescribe: kubectl describe pdb api-pdb -n disruption-lab
  nodeWorkloadCheck: kubectl get pods -A -o wide --field-selector spec.nodeName=kind-cluster-worker
  cordonCommand: kubectl cordon kind-cluster-worker
  drainPreview: kubectl drain kind-cluster-worker --ignore-daemonsets --delete-emptydir-data --dry-run=client
  uncordonCommand: kubectl uncordon kind-cluster-worker
  safeRemediationNote: review PodDisruptionBudget impact before any non-dry-run drain
EOF_BRIEF

mkdir -p /tmp/exam/q801
cat <<'EOF_CHECKLIST' > /tmp/exam/q801/disruption-planning-checklist.txt
PDB Inventory
- kubectl get pdb -A
- kubectl describe pdb api-pdb -n disruption-lab

Node Workload Audit
- kubectl get pods -A -o wide --field-selector spec.nodeName=kind-cluster-worker
- kubectl get deploy api -n disruption-lab

Safe Drain Sequence
- kubectl cordon kind-cluster-worker
- kubectl drain kind-cluster-worker --ignore-daemonsets --delete-emptydir-data --dry-run=client
- review PodDisruptionBudget impact before any non-dry-run drain
- kubectl uncordon kind-cluster-worker
EOF_CHECKLIST

kubectl get configmap disruption-planning-brief -n disruption-lab -o yaml > /tmp/exam/q801/disruption-planning-brief.yaml
```

Expected checks:

- `disruption-planning-brief` contains the intended node target, PDB inventory commands, node workload audit, and safe drain guidance
- `/tmp/exam/q801/disruption-planning-checklist.txt` contains the required sections and exact disruption-planning commands
- `/tmp/exam/q801/disruption-planning-brief.yaml` exports the repaired manifest
- stale unsafe actions such as deleting Pods, deleting PodDisruptionBudgets, or performing a live drain are removed
