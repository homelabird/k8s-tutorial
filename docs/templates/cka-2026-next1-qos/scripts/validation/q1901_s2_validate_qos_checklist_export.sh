#!/usr/bin/env bash
set -euo pipefail

CHECKLIST="/tmp/exam/q1901/qos-diagnostics-checklist.txt"
[[ -f "${CHECKLIST}" ]]

grep -Fx "Deployment Inventory" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment reporting-api -n qos-lab -o wide" "${CHECKLIST}" >/dev/null

grep -Fx "Resource Checks" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment reporting-api -n qos-lab -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment reporting-api -n qos-lab -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment reporting-api -n qos-lab -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment reporting-api -n qos-lab -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get pods -n qos-lab -l app=reporting-api -o jsonpath='{.items[0].status.qosClass}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get events -n qos-lab --sort-by=.lastTimestamp" "${CHECKLIST}" >/dev/null

grep -Fx "Safe Manifest Review" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment reporting-api -n qos-lab -o yaml" "${CHECKLIST}" >/dev/null
grep -Fx -- "- confirm requests, limits, QoS class, and namespace events before changing the Deployment manifest" "${CHECKLIST}" >/dev/null
