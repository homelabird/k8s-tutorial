#!/bin/bash
set -euo pipefail

EXPORT_FILE="/tmp/exam/q1/certificate-renewal-brief.yaml"
CHECKLIST_FILE="/tmp/exam/q1/certificate-expiry-checklist.txt"

[ -f "$EXPORT_FILE" ] || { echo "Expected manifest export at $EXPORT_FILE"; exit 1; }
[ -f "$CHECKLIST_FILE" ] || { echo "Expected checklist export at $CHECKLIST_FILE"; exit 1; }

export_key() {
  kubectl create --dry-run=client -f "$EXPORT_FILE" -o "jsonpath={.$1}" 2>/dev/null
}

[ "$(export_key metadata.name)" = "certificate-renewal-brief" ] || { echo "Exported manifest must contain certificate-renewal-brief"; exit 1; }
[ "$(export_key metadata.namespace)" = "pki-lab" ] || { echo "Exported manifest must contain namespace pki-lab"; exit 1; }
[ "$(export_key data.targetCertificate)" = "/etc/kubernetes/pki/apiserver.crt" ] || { echo "Exported manifest missing repaired targetCertificate"; exit 1; }
[ "$(export_key data.renewalCommand)" = "sudo kubeadm certs renew apiserver" ] || { echo "Exported manifest missing repaired renewalCommand"; exit 1; }
! grep -Fq '/etc/kubernetes/pki/etcd/server.crt' "$EXPORT_FILE" || { echo "Exported manifest still contains stale targetCertificate"; exit 1; }
! grep -Fq 'sudo kubeadm reset -f' "$EXPORT_FILE" || { echo "Exported manifest still contains unsafe renewal command"; exit 1; }
! grep -Fq 'sudo kubeadm reset -f' "$CHECKLIST_FILE" || { echo "Checklist must not reset the cluster"; exit 1; }
! grep -Fq 'sudo systemctl restart kubelet' "$CHECKLIST_FILE" || { echo "Checklist must not restart kubelet"; exit 1; }
! grep -Fq 'rm -f /etc/kubernetes/manifests/kube-apiserver.yaml' "$CHECKLIST_FILE" || { echo "Checklist must not delete static pod manifests"; exit 1; }

echo "certificate renewal manifest export and safety checks passed"
