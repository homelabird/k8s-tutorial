#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="affinity-lab"
DEPLOYMENT="api-fleet"

NODE_OS="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.nodeSelector.kubernetes\.io/os}')"
REPLICAS="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.replicas}')"
ANTI_KEY="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].topologyKey}')"
ANTI_APP="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].labelSelector.matchLabels.app}')"
SPREAD_KEY="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.topologySpreadConstraints[0].topologyKey}')"
SPREAD_MAX_SKEW="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.topologySpreadConstraints[0].maxSkew}')"
SPREAD_UNSAT="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.topologySpreadConstraints[0].whenUnsatisfiable}')"

[ "${NODE_OS}" = "linux" ] || { echo "api-fleet must target Linux nodes"; exit 1; }
[ "${REPLICAS}" = "1" ] || { echo "api-fleet must keep replicas: 1"; exit 1; }
[ "${ANTI_KEY}" = "kubernetes.io/hostname" ] || { echo "Anti-affinity must use topology key kubernetes.io/hostname"; exit 1; }
[ "${ANTI_APP}" = "api-fleet" ] || { echo "Anti-affinity must match app=api-fleet"; exit 1; }
[ "${SPREAD_KEY}" = "kubernetes.io/hostname" ] || { echo "Topology spread must use kubernetes.io/hostname"; exit 1; }
[ "${SPREAD_MAX_SKEW}" = "1" ] || { echo "Topology spread must use maxSkew 1"; exit 1; }
[ "${SPREAD_UNSAT}" = "ScheduleAnyway" ] || { echo "Topology spread must use whenUnsatisfiable ScheduleAnyway"; exit 1; }

echo "Deployment api-fleet uses the intended node selector, anti-affinity, and topology spread configuration"
