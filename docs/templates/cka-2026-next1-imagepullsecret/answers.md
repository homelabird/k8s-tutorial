# CKA 2026 Next Image Pull Secret Wave Answers

## Question 2001

One valid repair flow is:

```bash
kubectl apply -n registry-auth-lab -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: private-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: private-api
  template:
    metadata:
      labels:
        app: private-api
    spec:
      serviceAccountName: puller
      imagePullSecrets:
        - name: regcred
      containers:
        - name: api
          image: busybox:1.36
          command:
            - /bin/sh
            - -c
            - sleep 3600
EOF

kubectl rollout status deployment/private-api -n registry-auth-lab
kubectl get pods -n registry-auth-lab -l app=private-api -o jsonpath='{.items[0].spec.imagePullSecrets[0].name}{"\n"}'
```
