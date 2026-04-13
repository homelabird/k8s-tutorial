#!/usr/bin/env bash
set -euo pipefail

CHECKLIST="/tmp/exam/q2401/staticpod-diagnostics-checklist.txt"
[[ -f "${CHECKLIST}" ]]

grep -Fx "Mirror Pod Inventory" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get pod audit-agent-ckad9999 -n staticpod-lab -o wide" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get pod audit-agent-ckad9999 -n staticpod-lab -o jsonpath='{.spec.nodeName}'" "${CHECKLIST}" >/dev/null

grep -Fx "Static Pod Checks" "${CHECKLIST}" >/dev/null
grep -Fx -- "- sudo ls -l /etc/kubernetes/manifests/audit-agent.yaml" "${CHECKLIST}" >/dev/null
grep -Fx -- "- sudo sed -n '1,160p' /etc/kubernetes/manifests/audit-agent.yaml" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get pod audit-agent-ckad9999 -n staticpod-lab -o jsonpath='{.spec.hostNetwork}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get pod audit-agent-ckad9999 -n staticpod-lab -o jsonpath='{.spec.containers[0].command}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get events -n staticpod-lab --sort-by=.lastTimestamp" "${CHECKLIST}" >/dev/null

grep -Fx "Safe Manifest Review" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get pod audit-agent-ckad9999 -n staticpod-lab -o yaml" "${CHECKLIST}" >/dev/null
grep -Fx -- "- confirm manifest path, mirror pod inventory, hostNetwork setting, and container command before changing static pod manifests" "${CHECKLIST}" >/dev/null
