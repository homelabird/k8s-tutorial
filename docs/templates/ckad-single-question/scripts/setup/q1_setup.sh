#!/bin/bash
set -e

# Reset only the resources used by this template question.
kubectl delete deployment web-frontend -n app-team --ignore-not-found=true
kubectl delete namespace app-team --ignore-not-found=true
kubectl wait --for=delete namespace/app-team --timeout=60s >/dev/null 2>&1 || true

echo "Setup complete for Question 1 template"
exit 0
