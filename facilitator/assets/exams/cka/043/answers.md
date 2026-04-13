## Question 1: Static pod manifest and mirror pod diagnostics

Repair the static pod diagnostics brief and export both the repaired manifest and a plain-text checklist.

```bash
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: staticpod-diagnostics-brief
  namespace: staticpod-lab
data:
  targetMirrorPod: audit-agent-ckad9999
  mirrorPodInventory: kubectl get pod audit-agent-ckad9999 -n staticpod-lab -o wide
  staticPodPathCheck: sudo ls -l /etc/kubernetes/manifests/audit-agent.yaml
  manifestPreviewCheck: sudo sed -n '1,160p' /etc/kubernetes/manifests/audit-agent.yaml
  hostNetworkCheck: kubectl get pod audit-agent-ckad9999 -n staticpod-lab -o jsonpath='{.spec.hostNetwork}'
  containerCommandCheck: kubectl get pod audit-agent-ckad9999 -n staticpod-lab -o jsonpath='{.spec.containers[0].command}'
  nodeCheck: kubectl get pod audit-agent-ckad9999 -n staticpod-lab -o jsonpath='{.spec.nodeName}'
  eventCheck: kubectl get events -n staticpod-lab --sort-by=.lastTimestamp
  safeManifestNote: confirm manifest path, mirror pod inventory, hostNetwork setting, and container command before changing static pod manifests
EOF_BRIEF

mkdir -p /tmp/exam/q1
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/staticpod-diagnostics-checklist.txt
Mirror Pod Inventory
- kubectl get pod audit-agent-ckad9999 -n staticpod-lab -o wide
- kubectl get pod audit-agent-ckad9999 -n staticpod-lab -o jsonpath='{.spec.nodeName}'

Static Pod Checks
- sudo ls -l /etc/kubernetes/manifests/audit-agent.yaml
- sudo sed -n '1,160p' /etc/kubernetes/manifests/audit-agent.yaml
- kubectl get pod audit-agent-ckad9999 -n staticpod-lab -o jsonpath='{.spec.hostNetwork}'
- kubectl get pod audit-agent-ckad9999 -n staticpod-lab -o jsonpath='{.spec.containers[0].command}'
- kubectl get events -n staticpod-lab --sort-by=.lastTimestamp

Safe Manifest Review
- kubectl get pod audit-agent-ckad9999 -n staticpod-lab -o yaml
- confirm manifest path, mirror pod inventory, hostNetwork setting, and container command before changing static pod manifests
EOF_CHECKLIST

kubectl get configmap staticpod-diagnostics-brief -n staticpod-lab -o yaml > /tmp/exam/q1/staticpod-diagnostics-brief.yaml
```

Expected checks:

- `staticpod-diagnostics-brief` contains the intended mirror pod target, exact manifest path and mirror pod inspection commands, event visibility, and safe manifest guidance
- `/tmp/exam/q1/staticpod-diagnostics-checklist.txt` contains the required sections and exact static pod troubleshooting commands
- `/tmp/exam/q1/staticpod-diagnostics-brief.yaml` exports the repaired manifest
- stale unsafe actions such as deleting the mirror pod, restarting kubelet, or moving manifest files are removed
