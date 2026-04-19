# CKA 2026 Single Domain Drill 031 Answers

## Question 1

One valid repair flow is:

```bash
kubectl apply -n job-lab -f - <<'EOF'
apiVersion: batch/v1
kind: Job
metadata:
  name: report-batch
spec:
  completions: 1
  parallelism: 1
  backoffLimit: 1
  suspend: false
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: worker
          image: busybox:1.36
          command:
            - sh
            - -c
            - echo batch-ready && exit 0
EOF

kubectl wait --for=condition=complete job/report-batch -n job-lab --timeout=180s
kubectl logs -n job-lab -l job-name=report-batch
```
