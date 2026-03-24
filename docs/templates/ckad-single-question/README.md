# CKAD Single-Question Template

This scaffold is a minimal working example for authoring one CKAD-style question.

Use it in one of two ways:

1. Copy this directory into a new exam folder such as `facilitator/assets/exams/ckad/003/`
2. Copy only the `assessment.json` question block plus the matching `scripts/` files into an existing CKAD exam pack

## Included Files

- `labs.entry.json`: snippet to append to `facilitator/assets/exams/labs.json`
- `config.json`: exam-level configuration
- `assessment.json`: one example question
- `answers.md`: answer sheet entry for the same question
- `scripts/setup/q1_setup.sh`: environment preparation
- `scripts/validation/q1_s*_validate_*.sh`: grading steps

## How To Adapt It

1. Update exam metadata in `labs.entry.json` and `config.json`
2. Rewrite the question text in `assessment.json`
3. Keep setup idempotent so re-running the exam does not leave stale resources behind
4. Split grading into small validation scripts that each check one thing
5. If the learner needs starter files, generate them from `q1_setup.sh` under `/tmp/exam/q1`
6. Add the final explanation and sample commands to `answers.md`

## Runtime Constraints

- Only `scripts/` are shipped to the jumphost during exam preparation
- Any starter files must therefore be created by setup, not stored next to the question JSON
- Validation currently treats `exit code 0` as pass and non-zero as fail
- The UI shows `machineHostname`, `namespace`, and `concepts`, so keep them human-readable
