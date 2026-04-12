#!/bin/bash
set -euo pipefail

NAMESPACE="pki-lab"
CONFIGMAP="certificate-renewal-brief"

kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" >/dev/null 2>&1 || {
  echo "ConfigMap $CONFIGMAP not found"
  exit 1
}

get_key() {
  kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" -o jsonpath="{.data.$1}"
}

[ "$(get_key targetCertificate)" = "/etc/kubernetes/pki/apiserver.crt" ] || { echo "targetCertificate is incorrect"; exit 1; }
[ "$(get_key expiryCheck)" = "sudo kubeadm certs check-expiration" ] || { echo "expiryCheck is incorrect"; exit 1; }
[ "$(get_key dateInspection)" = "sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -dates" ] || { echo "dateInspection is incorrect"; exit 1; }
[ "$(get_key kubeconfigCheck)" = "sudo grep -n client-certificate-data /etc/kubernetes/admin.conf" ] || { echo "kubeconfigCheck is incorrect"; exit 1; }
[ "$(get_key renewalCommand)" = "sudo kubeadm certs renew apiserver" ] || { echo "renewalCommand is incorrect"; exit 1; }
[ "$(get_key readinessCheck)" = "kubectl get --raw='/readyz?verbose'" ] || { echo "readinessCheck is incorrect"; exit 1; }

echo "certificate renewal brief contract is repaired"
