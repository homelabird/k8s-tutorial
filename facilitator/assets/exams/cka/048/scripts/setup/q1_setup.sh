#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="dnspolicy-lab"

kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl delete deployment dns-client -n "${NAMESPACE}" --ignore-not-found >/dev/null

cat <<'EOF_DEPLOYMENT' | kubectl apply -n "${NAMESPACE}" -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dns-client
spec:
  replicas: 1
  selector:
    matchLabels:
      app: dns-client
  template:
    metadata:
      labels:
        app: dns-client
    spec:
      dnsPolicy: None
      dnsConfig:
        nameservers:
          - 8.8.8.8
        searches:
          - wrong.local
        options:
          - name: ndots
            value: "5"
      containers:
        - name: toolbox
          image: busybox:1.36
          command:
            - /bin/sh
            - -c
            - grep -q '^nameserver 1.1.1.1$' /etc/resolv.conf && grep -q '^search lab.local$' /etc/resolv.conf && grep -q 'options ndots:2' /etc/resolv.conf && sleep 3600
EOF_DEPLOYMENT
