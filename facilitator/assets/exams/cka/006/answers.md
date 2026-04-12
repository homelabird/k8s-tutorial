# CKA 2026 Single Domain Drill - RBAC Least Privilege

## Question 1: RBAC least-privilege repair

Create a namespace-scoped Role and RoleBinding so the existing ServiceAccount `report-reader` can only `get` and `list` Pods in namespace `rbac-lab`.

```yaml
cat <<'EOF_ROLE' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: report-reader
  namespace: rbac-lab
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
EOF_ROLE

cat <<'EOF_ROLEBINDING' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: report-reader
  namespace: rbac-lab
subjects:
- kind: ServiceAccount
  name: report-reader
  namespace: rbac-lab
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: report-reader
EOF_ROLEBINDING
```

Verify:

```bash
kubectl auth can-i get pods -n rbac-lab --as=system:serviceaccount:rbac-lab:report-reader
kubectl auth can-i list pods -n rbac-lab --as=system:serviceaccount:rbac-lab:report-reader
kubectl auth can-i create pods -n rbac-lab --as=system:serviceaccount:rbac-lab:report-reader
kubectl auth can-i get secrets -n rbac-lab --as=system:serviceaccount:rbac-lab:report-reader
```

The validator also checks that:

- the binding stays namespace-scoped in `rbac-lab`
- the Role stays limited to the `pods` resource
- no `ClusterRoleBinding/report-reader` exists
