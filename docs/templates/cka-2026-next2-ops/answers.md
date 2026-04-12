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

## Question 602: PKI and certificate expiry troubleshooting

Repair the certificate renewal brief and export both the repaired manifest and a plain-text checklist.

```bash
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: certificate-renewal-brief
  namespace: pki-lab
data:
  targetCertificate: /etc/kubernetes/pki/apiserver.crt
  expiryCheck: sudo kubeadm certs check-expiration
  dateInspection: sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -dates
  kubeconfigCheck: sudo grep -n client-certificate-data /etc/kubernetes/admin.conf
  renewalCommand: sudo kubeadm certs renew apiserver
  readinessCheck: kubectl get --raw='/readyz?verbose'
EOF_BRIEF

mkdir -p /tmp/exam/q602
cat <<'EOF_CHECKLIST' > /tmp/exam/q602/certificate-expiry-checklist.txt
Certificate Inspection
- sudo kubeadm certs check-expiration
- sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -dates
- sudo grep -n client-certificate-data /etc/kubernetes/admin.conf

Renewal Planning
- sudo kubeadm certs renew apiserver
- sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/exam/q602/kube-apiserver.yaml.bak

Post-Renewal Verification
- kubectl get --raw='/readyz?verbose'
- kubectl get pods -n kube-system -l component=kube-apiserver
EOF_CHECKLIST

kubectl get configmap certificate-renewal-brief -n pki-lab -o yaml > /tmp/exam/q602/certificate-renewal-brief.yaml
```

Expected checks:

- `certificate-renewal-brief` contains the intended certificate target, expiry inspection commands, kubeconfig check, and renewal guidance
- `/tmp/exam/q602/certificate-expiry-checklist.txt` contains the required sections and exact troubleshooting commands
- `/tmp/exam/q602/certificate-renewal-brief.yaml` exports the repaired manifest
- stale unsafe actions such as `kubeadm reset`, restarting kubelet, or deleting static pod manifests are removed


## Question 603: resource quota and LimitRange troubleshooting

Repair the resource guardrails brief and export both the repaired manifest and a plain-text checklist.

```bash
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: resource-guardrails-brief
  namespace: quota-lab
data:
  targetNamespace: quota-lab
  quotaInspection: kubectl get resourcequota -n quota-lab
  quotaDescribe: kubectl describe resourcequota compute-quota -n quota-lab
  limitRangeInspection: kubectl describe limitrange default-limits -n quota-lab
  workloadInspection: kubectl describe deployment api -n quota-lab
  recommendedPatch: kubectl set resources deployment/api -n quota-lab --requests=cpu=250m,memory=256Mi --limits=cpu=500m,memory=512Mi
EOF_BRIEF

mkdir -p /tmp/exam/q603
cat <<'EOF_CHECKLIST' > /tmp/exam/q603/resource-quota-checklist.txt
Quota Inspection
- kubectl get resourcequota -n quota-lab
- kubectl describe resourcequota compute-quota -n quota-lab

LimitRange Inspection
- kubectl describe limitrange default-limits -n quota-lab
- kubectl get limitrange default-limits -n quota-lab -o yaml

Workload Sizing Guidance
- kubectl describe deployment api -n quota-lab
- kubectl set resources deployment/api -n quota-lab --requests=cpu=250m,memory=256Mi --limits=cpu=500m,memory=512Mi
EOF_CHECKLIST

kubectl get configmap resource-guardrails-brief -n quota-lab -o yaml > /tmp/exam/q603/resource-guardrails-brief.yaml
```

Expected checks:

- `resource-guardrails-brief` contains the intended namespace target, quota inspection commands, LimitRange inspection, workload review, and safe resource patch guidance
- `/tmp/exam/q603/resource-quota-checklist.txt` contains the required sections and exact troubleshooting commands
- `/tmp/exam/q603/resource-guardrails-brief.yaml` exports the repaired manifest
- stale unsafe actions such as deleting ResourceQuota or LimitRange objects, scaling workloads to zero, or removing requests/limits are removed
