# CKA 2026 Single Domain Drill 050 Answers

## Question 1

One valid repair flow is:

```bash
kubectl apply -n downwardapi-lab -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: meta-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: meta-api
  template:
    metadata:
      labels:
        app: meta-api
    spec:
      containers:
        - name: api
          image: busybox:1.36
          command:
            - /bin/sh
            - -c
            - test -n "$POD_NAME" && test -n "$POD_NAMESPACE" && sleep 3600
          env:
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
EOF

kubectl rollout status deployment/meta-api -n downwardapi-lab
kubectl exec -n downwardapi-lab deploy/meta-api -- printenv POD_NAME POD_NAMESPACE
```
