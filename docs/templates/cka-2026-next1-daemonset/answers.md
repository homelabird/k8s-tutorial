# CKA 2026 Next DaemonSet Wave Answers

## Question 1001

One valid repair flow is:

```bash
kubectl apply -n daemonset-lab -f - <<'EOF'
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: log-agent
spec:
  selector:
    matchLabels:
      app: log-agent
  updateStrategy:
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: log-agent
    spec:
      nodeSelector:
        kubernetes.io/os: linux
      tolerations:
        - operator: Exists
      containers:
        - name: agent
          image: busybox:1.36
          command:
            - sh
            - -c
            - sleep 3600
EOF

kubectl rollout status daemonset/log-agent -n daemonset-lab
kubectl get daemonset log-agent -n daemonset-lab -o wide
```
