# CKA 2026 Single Domain Drill 030 Answers

## Question 1

One valid repair flow is:

```bash
kubectl apply -n cronjob-lab -f - <<'EOF'
apiVersion: batch/v1
kind: CronJob
metadata:
  name: log-pruner
spec:
  schedule: '*/15 * * * *'
  suspend: false
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          containers:
            - name: pruner
              image: busybox:1.36
              command:
                - sh
                - -c
                - echo prune && sleep 5
EOF

kubectl get cronjob log-pruner -n cronjob-lab -o wide
```
