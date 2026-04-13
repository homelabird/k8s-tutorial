#!/usr/bin/env bash
set -euo pipefail

EXPORT_FILE="/tmp/exam/q2501/projected-volume-brief.yaml"

[[ -f "${EXPORT_FILE}" ]]

grep -F "name: projected-volume-brief" "${EXPORT_FILE}" >/dev/null
grep -F "namespace: projectedvolume-lab" "${EXPORT_FILE}" >/dev/null
grep -F "targetDeployment: bundle-api" "${EXPORT_FILE}" >/dev/null
grep -F "safeManifestNote: confirm projected sources, item paths, and readOnly mount before changing the Deployment manifest" "${EXPORT_FILE}" >/dev/null

if grep -Fq "kubectl rollout restart deployment/bundle-api -n projectedvolume-lab" "${EXPORT_FILE}"; then
  exit 1
fi

if grep -Fq "kubectl delete pod -n projectedvolume-lab -l app=bundle-api" "${EXPORT_FILE}"; then
  exit 1
fi

if grep -Fq "kubectl patch configmap app-config" "${EXPORT_FILE}"; then
  exit 1
fi

if grep -Fq "kubectl patch deployment bundle-api" "${EXPORT_FILE}"; then
  exit 1
fi
