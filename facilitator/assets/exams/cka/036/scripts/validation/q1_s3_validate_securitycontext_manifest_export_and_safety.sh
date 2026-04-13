#!/bin/bash
set -euo pipefail

MANIFEST="/tmp/exam/q1/securitycontext-diagnostics-brief.yaml"
[ -f "$MANIFEST" ] || { echo "Manifest export missing"; exit 1; }

grep -F "targetDeployment: secure-api" "$MANIFEST" >/dev/null || { echo "Manifest targetDeployment is incorrect"; exit 1; }
grep -F "safeManifestNote:" "$MANIFEST" >/dev/null || { echo "Manifest safe note key is missing"; exit 1; }
grep -F "confirm runAsUser, fsGroup, seccomp, capability drop, and mount path before changing the Deployment manifest" "$MANIFEST" >/dev/null || {
  echo "Manifest safe note value is incorrect"
  exit 1
}

if grep -E "rollout restart|kubectl delete pod|kubectl patch deployment|restart the deployment" "$MANIFEST" >/dev/null; then
  echo "Manifest still contains unsafe remediation commands"
  exit 1
fi

echo "securitycontext manifest export is repaired"
