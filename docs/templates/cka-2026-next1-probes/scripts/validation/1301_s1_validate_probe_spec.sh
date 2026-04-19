#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="probe-lab"
DEPLOYMENT="health-api"

PORT="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].ports[0].containerPort}')"
STARTUP_PATH="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].startupProbe.httpGet.path}')"
STARTUP_PORT="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].startupProbe.httpGet.port}')"
LIVENESS_PATH="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.httpGet.path}')"
LIVENESS_PORT="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.httpGet.port}')"
READINESS_PATH="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.path}')"
READINESS_PORT="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.port}')"

[ "${PORT}" = "8080" ] || { echo "health-api must keep containerPort 8080"; exit 1; }
[ "${STARTUP_PATH}" = "/healthz" ] || { echo "startupProbe must check /healthz"; exit 1; }
[ "${STARTUP_PORT}" = "8080" ] || { echo "startupProbe must target port 8080"; exit 1; }
[ "${LIVENESS_PATH}" = "/healthz" ] || { echo "livenessProbe must check /healthz"; exit 1; }
[ "${LIVENESS_PORT}" = "8080" ] || { echo "livenessProbe must target port 8080"; exit 1; }
[ "${READINESS_PATH}" = "/healthz" ] || { echo "readinessProbe must check /healthz"; exit 1; }
[ "${READINESS_PORT}" = "8080" ] || { echo "readinessProbe must target port 8080"; exit 1; }

echo "Deployment health-api uses the intended container port and HTTP probe paths"
