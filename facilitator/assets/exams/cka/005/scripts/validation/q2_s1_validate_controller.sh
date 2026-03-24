#!/bin/bash
set -e

kubectl rollout status deployment ingress-nginx-controller -n ingress-nginx --timeout=180s >/dev/null 2>&1
echo "ingress-nginx controller is installed and ready"
exit 0
