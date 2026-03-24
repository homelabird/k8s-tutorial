# CKA 2026 Top 3 Drafts

These are draft question assets for the top three CKA-aligned additions identified from the current Linux Foundation and CNCF curriculum:

1. Pod Security Admission restricted profile
2. CoreDNS troubleshooting
3. Ingress controller installation and routing repair

## Intended Use

- Copy the question objects from `assessment.json` into an existing CKA exam pack
- Copy the matching `scripts/setup/` and `scripts/validation/` files into that pack
- Update question IDs if you append them to an existing exam

## Important Constraints

- Question 2 changes the cluster-wide CoreDNS ConfigMap and should only be used in:
  - a dedicated troubleshooting exam
  - an isolated environment
  - or as the final question in a pack where no later question depends on DNS
- Question 3 assumes internet access is available from the exam environment so Helm can fetch the ingress-nginx chart
- These are draft assets only. They are syntax-checked but not fully end-to-end executed in a running exam session
