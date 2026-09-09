# Staging Validation Fixtures

These manifests are operator-run, short-lived fixtures for validating the
current `online-shop-stage` runtime. They are intentionally outside Argo CD
source paths and must not become part of the desired GitOps application state.

- `baseline-traffic.yaml` generates controlled healthy traffic through ingress.
- `failure-traffic.yaml` generates controlled `/break` traffic for failure-path validation.
- `prometheus-precheck.yaml` queries the staging Prometheus service for the
  expected request and SLO signals.

Apply only the fixture required by the approved validation step. Remove the
created Pod after the observation window and record accepted results in
`docs/validation-history.md`.
