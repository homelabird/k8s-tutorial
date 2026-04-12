# CKA 2026 Single Domain Drill - PKI and certificate expiry troubleshooting

## Question 1: PKI and certificate expiry troubleshooting

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

mkdir -p /tmp/exam/q1
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/certificate-expiry-checklist.txt
Certificate Inspection
- sudo kubeadm certs check-expiration
- sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -dates
- sudo grep -n client-certificate-data /etc/kubernetes/admin.conf

Renewal Planning
- sudo kubeadm certs renew apiserver
- sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/exam/q1/kube-apiserver.yaml.bak

Post-Renewal Verification
- kubectl get --raw='/readyz?verbose'
- kubectl get pods -n kube-system -l component=kube-apiserver
EOF_CHECKLIST

kubectl get configmap certificate-renewal-brief -n pki-lab -o yaml > /tmp/exam/q1/certificate-renewal-brief.yaml
```

Expected checks:

- `certificate-renewal-brief` contains the intended certificate target, expiry inspection commands, kubeconfig check, and renewal guidance
- `/tmp/exam/q1/certificate-expiry-checklist.txt` contains the required sections and exact troubleshooting commands
- `/tmp/exam/q1/certificate-renewal-brief.yaml` exports the repaired manifest
- stale unsafe actions such as `kubeadm reset`, restarting kubelet, or deleting static pod manifests are removed
