#!/bin/bash
set -e

POD_JSON=$(kubectl get pod restricted-shell -n secure-workloads -o json 2>/dev/null || true)

if [ -z "$POD_JSON" ]; then
  echo "Pod not found"
  exit 1
fi

RUN_AS_NON_ROOT=$(kubectl get pod restricted-shell -n secure-workloads -o jsonpath='{.spec.securityContext.runAsNonRoot}')
RUN_AS_USER=$(kubectl get pod restricted-shell -n secure-workloads -o jsonpath='{.spec.securityContext.runAsUser}')
SECCOMP=$(kubectl get pod restricted-shell -n secure-workloads -o jsonpath='{.spec.securityContext.seccompProfile.type}')
ALLOW_PRIV_ESC=$(kubectl get pod restricted-shell -n secure-workloads -o jsonpath='{.spec.containers[0].securityContext.allowPrivilegeEscalation}')
CAPS=$(kubectl get pod restricted-shell -n secure-workloads -o jsonpath='{.spec.containers[0].securityContext.capabilities.drop[*]}')

if [ "$RUN_AS_NON_ROOT" = "true" ] && \
   [ "$RUN_AS_USER" = "1000" ] && \
   [ "$SECCOMP" = "RuntimeDefault" ] && \
   [ "$ALLOW_PRIV_ESC" = "false" ] && \
   echo "$CAPS" | grep -qw "ALL"; then
  echo "Pod security context matches restricted requirements"
  exit 0
fi

echo "Pod security context does not match expected restricted settings"
exit 1
