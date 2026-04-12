# CKA 2026 Next Ops Wave 2 Drafts

These drafts cover the next recommended ops-oriented packs from the `cka-022+` roadmap:

1. kubelet and node NotReady troubleshooting
2. PKI and certificate expiry troubleshooting
3. resource quota and LimitRange troubleshooting

## Intended Use

- Use `assessment.json` as the authoring baseline for the next facilitator expansion wave.
- Use `answers.md`, `scripts/setup/`, and `scripts/validation/` as the implementation contract for each drill.
- Keep these drills single-domain and deterministic before promoting them into real facilitator packs.

## Current Template State

- Question `601` (`kubelet and node NotReady troubleshooting`) is now fully scaffolded with `answers.md`, `scripts/setup/`, and validation scripts.
- Question `601` has now been promoted into facilitator pack `cka-022`.
- Question `602` (`PKI and certificate expiry troubleshooting`) is now fully scaffolded with `answers.md`, `scripts/setup/`, and validation scripts.
- Question `602` has now been promoted into facilitator pack `cka-023`.
- Question `603` (`resource quota and LimitRange troubleshooting`) is now fully scaffolded with `answers.md`, `scripts/setup/`, and validation scripts.
- Question `603` has not yet been promoted and is planned as facilitator pack `cka-024`.

## Important Constraints

- Question `601` should stay in the `planning + evidence export` lane. It should validate exact node-condition checks, kubelet service checks, kubelet log hints, and safe maintenance notes without stopping or restarting kubelet.
- Question `601` should export exact evidence files instead of attempting live node repair inside the drill.
- Question `601` should avoid `reboot`, `systemctl restart kubelet`, and `kubectl drain` as corrective actions in the expected answer.
- Question `602` should stay in the `planning + evidence export` lane. It should validate certificate inspection, kubeadm expiry checks, renewal planning, and readiness verification without running live certificate renewal.
- Question `602` should export exact evidence files instead of rotating certificates or rewriting static pod manifests inside the drill.
- Question `602` should avoid `kubeadm reset`, `systemctl restart kubelet`, and deleting manifests as corrective actions in the expected answer.
- Question `603` should stay in the `planning + evidence export` lane. It should validate exact resource quota, LimitRange, workload sizing, and safe remediation guidance without deleting guardrail objects or mutating live workload replicas.
- Question `603` should export exact evidence files instead of deleting quota objects or stripping requests and limits from workloads inside the drill.
- Question `603` should avoid `kubectl delete resourcequota`, `kubectl delete limitrange`, and `kubectl scale deployment api -n quota-lab --replicas=0` as corrective actions in the expected answer.

## Recommended Promotion Order

1. `q603` -> `facilitator/assets/exams/cka/024`

## Planned Facilitator Mapping

- `q601` -> `facilitator/assets/exams/cka/022`
- `q602` -> `facilitator/assets/exams/cka/023`
- `q603` -> `facilitator/assets/exams/cka/024`
