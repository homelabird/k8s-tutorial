#!/bin/bash
set -e

delete_pod_safely() {
  pod_name="$1"
  namespace="$2"

  kubectl delete pod "$pod_name" -n "$namespace" --ignore-not-found=true --timeout=30s || true

  if kubectl get pod "$pod_name" -n "$namespace" >/dev/null 2>&1; then
    kubectl delete pod "$pod_name" -n "$namespace" --force --grace-period=0 --ignore-not-found=true
  fi

  kubectl wait --for=delete "pod/$pod_name" -n "$namespace" --timeout=60s >/dev/null 2>&1 || true
}

kubectl create namespace dns-lab --dry-run=client -o yaml | kubectl apply -f -

kubectl delete deployment web -n dns-lab --ignore-not-found=true
kubectl delete service web -n dns-lab --ignore-not-found=true
delete_pod_safely dns-check dns-lab

kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: dns-lab
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
        - name: nginx
          image: nginx:1.27.0-alpine
          ports:
            - containerPort: 80
EOF

kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: web
  namespace: dns-lab
spec:
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 80
EOF

kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: dns-check
  namespace: dns-lab
spec:
  containers:
    - name: busybox
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
EOF

broken_ready=0
for attempt in $(seq 1 10); do
  kubectl get configmap coredns -n kube-system -o yaml \
    | sed 's/kubernetes cluster\.local in-addr\.arpa ip6\.arpa/kubernetes broken.local in-addr.arpa ip6.arpa/' \
    | kubectl apply -f -

  kubectl rollout restart deployment coredns -n kube-system
  kubectl rollout status deployment coredns -n kube-system --timeout=120s

  corefile="$(kubectl get configmap coredns -n kube-system -o jsonpath='{.data.Corefile}')"
  if printf '%s' "$corefile" | grep -F 'kubernetes broken.local in-addr.arpa ip6.arpa' >/dev/null; then
    broken_ready=1
    break
  fi

  sleep 2
done

if [ "$broken_ready" -ne 1 ]; then
  echo "Failed to persist broken.local CoreDNS config" >&2
  exit 1
fi

echo "Setup complete for Question 3"
exit 0
