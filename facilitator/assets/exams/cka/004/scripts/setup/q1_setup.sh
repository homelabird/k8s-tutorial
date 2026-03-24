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

cat <<'EOF' | kubectl create configmap coredns --dry-run=client -n kube-system --from-file=Corefile=/dev/stdin -o yaml | kubectl apply -f -
.:53 {
    errors
    health
    ready
    kubernetes broken.local in-addr.arpa ip6.arpa {
      pods insecure
      fallthrough in-addr.arpa ip6.arpa
      ttl 30
    }
    prometheus :9153
    forward . /etc/resolv.conf
    cache 30
    loop
    reload
    loadbalance
}
EOF

kubectl rollout restart deployment coredns -n kube-system
kubectl rollout status deployment coredns -n kube-system --timeout=120s

echo "Setup complete for Question 1"
exit 0
