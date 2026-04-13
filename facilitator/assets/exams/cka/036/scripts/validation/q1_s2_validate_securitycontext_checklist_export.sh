#!/bin/bash
set -euo pipefail

CHECKLIST="/tmp/exam/q1/securitycontext-diagnostics-checklist.txt"
[ -f "$CHECKLIST" ] || { echo "Checklist export missing"; exit 1; }

grep -Fx "Deployment Inventory" "$CHECKLIST" >/dev/null || { echo "Missing Deployment Inventory section"; exit 1; }
grep -Fx -- "- kubectl get deployment secure-api -n securitycontext-lab -o wide" "$CHECKLIST" >/dev/null || { echo "Missing deployment inventory command"; exit 1; }
grep -Fx -- "- kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.securityContext.runAsUser}'" "$CHECKLIST" >/dev/null || { echo "Missing runAsUser check"; exit 1; }

grep -Fx "Security Context Checks" "$CHECKLIST" >/dev/null || { echo "Missing Security Context Checks section"; exit 1; }
grep -Fx -- "- kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.securityContext.fsGroup}'" "$CHECKLIST" >/dev/null || { echo "Missing fsGroup check"; exit 1; }
grep -Fx -- "- kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.containers[0].securityContext.seccompProfile.type}'" "$CHECKLIST" >/dev/null || { echo "Missing seccomp check"; exit 1; }
grep -Fx -- "- kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.containers[0].securityContext.allowPrivilegeEscalation}'" "$CHECKLIST" >/dev/null || { echo "Missing allowPrivilegeEscalation check"; exit 1; }
grep -Fx -- "- kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.containers[0].securityContext.capabilities.drop[0]}'" "$CHECKLIST" >/dev/null || { echo "Missing capabilities drop check"; exit 1; }
grep -Fx -- "- kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'" "$CHECKLIST" >/dev/null || { echo "Missing mount path check"; exit 1; }
grep -Fx -- "- kubectl get events -n securitycontext-lab --sort-by=.lastTimestamp" "$CHECKLIST" >/dev/null || { echo "Missing event check"; exit 1; }

grep -Fx "Safe Manifest Review" "$CHECKLIST" >/dev/null || { echo "Missing Safe Manifest Review section"; exit 1; }
grep -Fx -- "- kubectl get deployment secure-api -n securitycontext-lab -o yaml" "$CHECKLIST" >/dev/null || { echo "Missing manifest review command"; exit 1; }
grep -Fx -- "- confirm runAsUser, fsGroup, seccomp, capability drop, and mount path before changing the Deployment manifest" "$CHECKLIST" >/dev/null || { echo "Missing safe manifest note"; exit 1; }

echo "securitycontext checklist export is repaired"
