#!/bin/bash
set -e

kubectl create namespace dns-lab --dry-run=client -o yaml | kubectl apply -f -

kubectl delete deployment web -n dns-lab --ignore-not-found=true
kubectl delete service web -n dns-lab --ignore-not-found=true
kubectl delete pod dns-check -n dns-lab --ignore-not-found=true

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

# Intentionally break internal cluster DNS by changing the CoreDNS kubernetes zone.
kubectl get configmap coredns -n kube-system -o jsonpath='{.data.Corefile}' > /tmp/q102-corefile.backup
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

echo "Setup complete for Question 102"
exit 0
