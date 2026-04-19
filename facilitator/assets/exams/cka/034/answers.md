# CKA 2026 Single Domain Drill 034 Answers

## Question 1

One valid repair flow is:

```bash
kubectl apply -n affinity-lab -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-fleet
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api-fleet
  template:
    metadata:
      labels:
        app: api-fleet
    spec:
      nodeSelector:
        kubernetes.io/os: linux
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchLabels:
                  app: api-fleet
              topologyKey: kubernetes.io/hostname
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: kubernetes.io/hostname
          whenUnsatisfiable: ScheduleAnyway
          labelSelector:
            matchLabels:
              app: api-fleet
      containers:
        - name: api
          image: busybox:1.36
          command:
            - /bin/sh
            - -c
            - sleep 3600
EOF

kubectl rollout status deployment/api-fleet -n affinity-lab
kubectl get pods -n affinity-lab -l app=api-fleet -o wide
```
