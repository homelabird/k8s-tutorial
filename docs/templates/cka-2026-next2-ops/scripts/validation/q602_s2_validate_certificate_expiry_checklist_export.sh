#!/bin/bash
set -euo pipefail

EXPORT_FILE="/tmp/exam/q602/certificate-expiry-checklist.txt"
[ -f "$EXPORT_FILE" ] || { echo "Expected checklist export at $EXPORT_FILE"; exit 1; }

grep -Fxq 'Certificate Inspection' "$EXPORT_FILE" || { echo "Checklist missing Certificate Inspection section"; exit 1; }
grep -Fxq 'Renewal Planning' "$EXPORT_FILE" || { echo "Checklist missing Renewal Planning section"; exit 1; }
grep -Fxq 'Post-Renewal Verification' "$EXPORT_FILE" || { echo "Checklist missing Post-Renewal Verification section"; exit 1; }
grep -Fq 'sudo kubeadm certs check-expiration' "$EXPORT_FILE" || { echo "Checklist missing kubeadm expiry check"; exit 1; }
grep -Fq 'sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -dates' "$EXPORT_FILE" || { echo "Checklist missing openssl date inspection"; exit 1; }
grep -Fq 'sudo grep -n client-certificate-data /etc/kubernetes/admin.conf' "$EXPORT_FILE" || { echo "Checklist missing kubeconfig certificate check"; exit 1; }
grep -Fq 'sudo kubeadm certs renew apiserver' "$EXPORT_FILE" || { echo "Checklist missing renewal planning command"; exit 1; }
grep -Fq 'sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/exam/q602/kube-apiserver.yaml.bak' "$EXPORT_FILE" || { echo "Checklist missing manifest backup step"; exit 1; }
grep -Fq "kubectl get --raw='/readyz?verbose'" "$EXPORT_FILE" || { echo "Checklist missing readiness verification"; exit 1; }
grep -Fq 'kubectl get pods -n kube-system -l component=kube-apiserver' "$EXPORT_FILE" || { echo "Checklist missing kube-apiserver pod verification"; exit 1; }

echo "certificate expiry checklist export is valid"
