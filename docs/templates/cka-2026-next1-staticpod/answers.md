# CKA 2026 Next Static Pod Wave Answers

## Question 2401

One valid repair flow is:

```bash
cat <<'EOF' > /etc/kubernetes/manifests/audit-agent.yaml
apiVersion: v1
kind: Pod
metadata:
  name: audit-agent
  namespace: staticpod-lab
  labels:
    app: audit-agent
spec:
  hostNetwork: true
  containers:
    - name: agent
      image: busybox:1.36
      command:
        - /bin/sh
        - -c
        - while true; do echo static-pod-audit; sleep 30; done
EOF
```

Then wait for the mirror Pod to appear and become Ready:

```bash
kubectl get pods -n staticpod-lab -l app=audit-agent -w
```
