# CKA 2026 Single Domain Drill - ConfigMap and Secret Repair

## Question 1: repair ConfigMap and Secret-backed workload configuration

Repair the `report-viewer` Deployment so it reads all runtime configuration from the intended ConfigMap and Secret. Keep the Secret-backed values externalized.

```yaml
kubectl set env deployment/report-viewer -n config-lab APP_MODE- REPORT_USER- REPORT_PASS-

kubectl patch deployment report-viewer -n config-lab --type strategic -p '{
  "spec": {
    "template": {
      "spec": {
        "containers": [
          {
            "name": "viewer",
            "env": [
              {
                "name": "APP_MODE",
                "valueFrom": {
                  "configMapKeyRef": {
                    "name": "report-config",
                    "key": "APP_MODE"
                  }
                }
              },
              {
                "name": "REPORT_USER",
                "valueFrom": {
                  "secretKeyRef": {
                    "name": "report-credentials",
                    "key": "username"
                  }
                }
              },
              {
                "name": "REPORT_PASS",
                "valueFrom": {
                  "secretKeyRef": {
                    "name": "report-credentials",
                    "key": "password"
                  }
                }
              }
            ]
          }
        ]
      }
    }
  }
}'
```

```bash
kubectl rollout status deployment/report-viewer -n config-lab
```

The validator also checks that:

- `APP_MODE` comes from ConfigMap `report-config` key `APP_MODE`
- `REPORT_USER` and `REPORT_PASS` come from Secret `report-credentials`
- no hardcoded replacement is used for the Secret-backed values
- the Deployment becomes Available
