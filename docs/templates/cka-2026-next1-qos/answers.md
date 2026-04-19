# CKA 2026 Next QoS Wave Answers

## Question 1901

One valid repair flow is:

```bash
kubectl apply -n qos-lab -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: reporting-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: reporting-api
  template:
    metadata:
      labels:
        app: reporting-api
    spec:
      containers:
        - name: api
          image: busybox:1.36
          command:
            - /bin/sh
            - -c
            - sleep 3600
          resources:
            requests:
              cpu: 250m
              memory: 256Mi
            limits:
              cpu: 250m
              memory: 256Mi
EOF

kubectl rollout status deployment/reporting-api -n qos-lab
kubectl get pods -n qos-lab -l app=reporting-api -o jsonpath='{.items[0].status.qosClass}{"\n"}'
```
