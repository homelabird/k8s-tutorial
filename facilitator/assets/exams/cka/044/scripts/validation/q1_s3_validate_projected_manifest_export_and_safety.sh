#!/usr/bin/env bash
set -euo pipefail

MANIFEST="/tmp/exam/q1/projected-volume-brief.yaml"
[[ -f "${MANIFEST}" ]]

grep -F "targetDeployment: bundle-api" "${MANIFEST}" >/dev/null
grep -F "safeManifestNote:" "${MANIFEST}" >/dev/null
grep -F "confirm projected sources, item paths, and readOnly mount before changing the Deployment manifest" "${MANIFEST}" >/dev/null

! grep -E "kubectl rollout restart deployment/bundle-api|kubectl delete pod -n projectedvolume-lab -l app=bundle-api|kubectl patch configmap app-config|kubectl patch deployment bundle-api|restart the deployment and patch live source objects" "${MANIFEST}" >/dev/null
