#!/usr/bin/env bash
set -euo pipefail

MANIFEST="/tmp/exam/q2701/subpath-diagnostics-brief.yaml"

[[ -f "${MANIFEST}" ]]
grep -Fx "  targetDeployment: subpath-api" "${MANIFEST}" >/dev/null
grep -Fx "  safeManifestNote: confirm ConfigMap item path, subPath, and target mount path before changing the Deployment manifest" "${MANIFEST}" >/dev/null
! grep -Eq 'kubectl rollout restart deployment/subpath-api|kubectl delete pod -n subpath-lab -l app=subpath-api|kubectl patch configmap app-config|kubectl patch deployment subpath-api|restart the deployment and patch the live ConfigMap' "${MANIFEST}"
