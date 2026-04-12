## Question 601: kubelet and node NotReady troubleshooting

Repair the node recovery brief and export both the repaired manifest and a plain-text checklist.

```bash
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: node-recovery-brief
  namespace: node-health-lab
data:
  targetNode: kind-cluster-worker
  nodeConditionCheck: kubectl describe node kind-cluster-worker | grep -A3 Conditions
  kubeletServiceCheck: sudo systemctl status kubelet
  kubeletLogCheck: sudo journalctl -u kubelet -n 50
  configCheck: sudo test -f /var/lib/kubelet/config.yaml
  runtimeCheck: sudo crictl info
EOF_BRIEF

mkdir -p /tmp/exam/q601
cat <<'EOF_CHECKLIST' > /tmp/exam/q601/node-notready-checklist.txt
Node Conditions
- kubectl get nodes
- kubectl describe node kind-cluster-worker | grep -A3 Conditions

Kubelet Service
- sudo systemctl status kubelet
- sudo journalctl -u kubelet -n 50

Runtime and Config
- sudo crictl info
- sudo test -f /var/lib/kubelet/config.yaml
EOF_CHECKLIST

kubectl get configmap node-recovery-brief -n node-health-lab -o yaml > /tmp/exam/q601/node-recovery-brief.yaml
```

Expected checks:

- `node-recovery-brief` contains the intended node target, kubelet checks, and runtime/config inspection commands
- `/tmp/exam/q601/node-notready-checklist.txt` contains the required sections and exact troubleshooting commands
- `/tmp/exam/q601/node-recovery-brief.yaml` exports the repaired manifest
- stale unsafe actions such as restarting kubelet, rebooting the node, or draining nodes are removed
