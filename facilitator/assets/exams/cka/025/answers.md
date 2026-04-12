# CKA 2026 Single Domain Drill - Container runtime and CRI endpoint diagnostics

## Question 1: container runtime and CRI endpoint diagnostics

Repair the runtime diagnostics brief and export both the repaired manifest and a plain-text checklist.

```bash
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: runtime-diagnostics-brief
  namespace: runtime-lab
data:
  targetNode: kind-cluster-control-plane
  kubeletConfigCheck: sudo grep -n containerRuntimeEndpoint /var/lib/kubelet/config.yaml
  runtimeSocketCheck: sudo test -S /run/containerd/containerd.sock
  crictlInfoCheck: sudo crictl --runtime-endpoint unix:///run/containerd/containerd.sock info
  crictlPodsCheck: sudo crictl --runtime-endpoint unix:///run/containerd/containerd.sock pods
  runtimeServiceCheck: sudo systemctl status containerd
EOF_BRIEF

mkdir -p /tmp/exam/q1
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/runtime-diagnostics-checklist.txt
Kubelet Wiring
- sudo grep -n containerRuntimeEndpoint /var/lib/kubelet/config.yaml
- sudo test -f /var/lib/kubelet/config.yaml

CRI Connectivity
- sudo test -S /run/containerd/containerd.sock
- sudo crictl --runtime-endpoint unix:///run/containerd/containerd.sock info
- sudo crictl --runtime-endpoint unix:///run/containerd/containerd.sock pods

Runtime Service
- sudo systemctl status containerd
- sudo crictl --runtime-endpoint unix:///run/containerd/containerd.sock ps -a
EOF_CHECKLIST

kubectl get configmap runtime-diagnostics-brief -n runtime-lab -o yaml > /tmp/exam/q1/runtime-diagnostics-brief.yaml
```

Expected checks:

- `runtime-diagnostics-brief` contains the intended node target, kubelet runtime-endpoint check, CRI socket inspection, crictl commands, and safe runtime service guidance
- `/tmp/exam/q1/runtime-diagnostics-checklist.txt` contains the required sections and exact runtime troubleshooting commands
- `/tmp/exam/q1/runtime-diagnostics-brief.yaml` exports the repaired manifest
- stale unsafe actions such as restarting kubelet, rewriting `/var/lib/kubelet/config.yaml`, or stopping/restarting containerd are removed
