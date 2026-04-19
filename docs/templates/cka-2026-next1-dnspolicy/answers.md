# CKA 2026 Next DNS Policy Wave Answers

## Question 4801

One valid repair flow is:

```bash
kubectl apply -n dnspolicy-lab -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dns-client
spec:
  replicas: 1
  selector:
    matchLabels:
      app: dns-client
  template:
    metadata:
      labels:
        app: dns-client
    spec:
      dnsPolicy: None
      dnsConfig:
        nameservers:
          - 1.1.1.1
        searches:
          - lab.local
        options:
          - name: ndots
            value: "2"
      containers:
        - name: toolbox
          image: busybox:1.36
          command:
            - /bin/sh
            - -c
            - grep -q '^nameserver 1.1.1.1$' /etc/resolv.conf && grep -q '^search lab.local$' /etc/resolv.conf && grep -q 'options ndots:2' /etc/resolv.conf && sleep 3600
EOF

kubectl rollout status deployment/dns-client -n dnspolicy-lab
kubectl exec -n dnspolicy-lab deploy/dns-client -- cat /etc/resolv.conf
```
