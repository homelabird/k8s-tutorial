#!/usr/bin/env bash
set -euo pipefail

kubectl rollout status deployment/reporting-api -n qos-lab --timeout=180s >/dev/null || {
  echo "Deployment reporting-api did not become Available"
  exit 1
}

echo "Deployment reporting-api becomes Available after the resource repair"
