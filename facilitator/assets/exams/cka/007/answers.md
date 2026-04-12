# CKA 2026 Single Domain Drill - Deployment Rollout and Rollback

## Question 1: controlled rollout and rollback

The existing Deployment `web-app` in namespace `rollout-lab` should be updated to `nginx:1.25.5`, its rolling update strategy should be tightened, rollout history should be written to `/tmp/exam/q1/rollout-history.txt`, and the Deployment should then be rolled back to the original image.

```bash
kubectl patch deployment web-app -n rollout-lab --type merge -p '{
  "spec": {
    "strategy": {
      "type": "RollingUpdate",
      "rollingUpdate": {
        "maxUnavailable": 1,
        "maxSurge": 1
      }
    }
  }
}'

kubectl annotate deployment web-app -n rollout-lab \
  kubernetes.io/change-cause='update image to nginx:1.25.5' \
  --overwrite

kubectl set image deployment/web-app nginx=nginx:1.25.5 -n rollout-lab
kubectl rollout status deployment/web-app -n rollout-lab

kubectl rollout history deployment/web-app -n rollout-lab > /tmp/exam/q1/rollout-history.txt

kubectl rollout undo deployment/web-app -n rollout-lab
kubectl rollout status deployment/web-app -n rollout-lab
```

The validator also checks that:

- the Deployment strategy stays `RollingUpdate` with `maxUnavailable=1` and `maxSurge=1`
- ReplicaSet history includes both `nginx:1.25.3` and `nginx:1.25.5`
- the final live Deployment returns to `nginx:1.25.3`
