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
kubectl delete deployment coredns -n dns-lab --ignore-not-found=true
kubectl delete service web -n dns-lab --ignore-not-found=true
kubectl delete service coredns -n dns-lab --ignore-not-found=true
delete_pod_safely dns-check dns-lab
kubectl delete configmap coredns -n dns-lab --ignore-not-found=true
kubectl delete serviceaccount coredns -n dns-lab --ignore-not-found=true
kubectl delete clusterrolebinding dns-lab-coredns --ignore-not-found=true

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
kind: ServiceAccount
metadata:
  name: coredns
  namespace: dns-lab
EOF

kubectl apply -f - <<'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: dns-lab-coredns
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:coredns
subjects:
  - kind: ServiceAccount
    name: coredns
    namespace: dns-lab
EOF

cat <<'EOF' | kubectl create configmap coredns --dry-run=client -n dns-lab --from-file=Corefile=/dev/stdin -o yaml | kubectl apply -f -
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
    cache 30
    loop
    reload
    loadbalance
}
EOF

kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: coredns
  namespace: dns-lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: coredns
  template:
    metadata:
      labels:
        app: coredns
    spec:
      serviceAccountName: coredns
      containers:
        - name: coredns
          image: coredns/coredns:1.11.1
          args: ["-conf", "/etc/coredns/Corefile"]
          ports:
            - name: dns-udp
              containerPort: 53
              protocol: UDP
            - name: dns-tcp
              containerPort: 53
              protocol: TCP
            - name: metrics
              containerPort: 9153
              protocol: TCP
          livenessProbe:
            httpGet:
              path: /health
              port: 8080
              scheme: HTTP
          readinessProbe:
            httpGet:
              path: /ready
              port: 8181
              scheme: HTTP
          volumeMounts:
            - name: config-volume
              mountPath: /etc/coredns
      volumes:
        - name: config-volume
          configMap:
            name: coredns
            items:
              - key: Corefile
                path: Corefile
EOF

kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: coredns
  namespace: dns-lab
spec:
  selector:
    app: coredns
  ports:
    - name: dns-udp
      port: 53
      protocol: UDP
      targetPort: 53
    - name: dns-tcp
      port: 53
      protocol: TCP
      targetPort: 53
EOF

kubectl rollout status deployment coredns -n dns-lab --timeout=120s

DNS_SERVICE_IP=$(kubectl get service coredns -n dns-lab -o jsonpath='{.spec.clusterIP}')

kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: dns-check
  namespace: dns-lab
spec:
  dnsPolicy: None
  dnsConfig:
    nameservers:
      - ${DNS_SERVICE_IP}
    searches:
      - dns-lab.svc.cluster.local
      - svc.cluster.local
      - cluster.local
  containers:
    - name: busybox
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
EOF

echo "Setup complete for Question 2"
exit 0
