#!/bin/bash
set -e

kubectl create namespace ingress-lab --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace ingress-nginx --dry-run=client -o yaml | kubectl apply -f -

kubectl delete ingress web-ingress -n ingress-lab --ignore-not-found=true
kubectl delete service web-service -n ingress-lab --ignore-not-found=true
kubectl delete deployment web-app -n ingress-lab --ignore-not-found=true
kubectl delete pod ingress-check -n ingress-lab --ignore-not-found=true

kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: ingress-lab
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
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
  name: web-service
  namespace: ingress-lab
spec:
  selector:
    app: web-app
  ports:
    - port: 80
      targetPort: 80
EOF

kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
  namespace: ingress-lab
spec:
  ingressClassName: broken
  rules:
    - host: app.example.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: wrong-service
                port:
                  number: 80
EOF

kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: ingress-check
  namespace: ingress-lab
spec:
  containers:
    - name: curl
      image: curlimages/curl:8.7.1
      command: ["sh", "-c", "sleep 3600"]
EOF

echo "Setup complete for Question 3"
exit 0
