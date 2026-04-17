#!/usr/bin/env bash
set -euo pipefail

MANIFEST="/tmp/exam/q1/lifecycle-diagnostics-brief.yaml"
[[ -f "$MANIFEST" ]]

grep -F "targetDeployment: lifecycle-api" "$MANIFEST" >/dev/null
grep -F "safeManifestNote" "$MANIFEST" >/dev/null
grep -F "confirm lifecycle preStop commands and termination grace period before changing workload manifests or forcing pod deletion" "$MANIFEST" >/dev/null
! grep -Eq 'kubectl delete pod -n lifecycle-lab -l app=lifecycle-api|kubectl rollout restart deployment lifecycle-api|kubectl patch deployment lifecycle-api|force-delete' "$MANIFEST"
