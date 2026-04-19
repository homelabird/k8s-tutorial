# CKA 2026 Single Domain Drill 049 Answers

## Question 1

One valid repair flow is:

```bash
kubectl apply -n lifecycle-lab -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: lifecycle-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: lifecycle-api
  template:
    metadata:
      labels:
        app: lifecycle-api
    spec:
      terminationGracePeriodSeconds: 30
      containers:
        - name: api
          image: busybox:1.36
          command:
            - /bin/sh
            - -c
            - while true; do sleep 30; done
          lifecycle:
            preStop:
              exec:
                command:
                  - /bin/sh
                  - -c
                  - sleep 5
EOF

kubectl rollout status deployment/lifecycle-api -n lifecycle-lab | tee /tmp/exam/q1/lifecycle-rollout-status.txt
```
