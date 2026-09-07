# Staging Foundation Terraform Preflight

Date: 2026-09-07

## Scope

This is a read-only preflight for the existing `sre-platform-staging-507220` foundation. No cloud write, Terraform initialization, import, plan, or apply was performed.

## Verified Invariants

- An active gcloud authentication state was present; account identity details were not recorded.
- The configured project and explicit target both resolved to `sre-platform-staging-507220`.
- The target project was active and had the existing foundation labels.
- Billing was enabled. One existing 100 CAD budget was scoped to exactly that project through its numeric project reference.
- The billing boundary retained `roles/billing.costsManager`; broad `roles/billing.admin` and public principals were absent.
- The direct state-bucket IAM policy contained no public principals or legacy bucket pseudo-principals.
- The state bucket existed in `US-CENTRAL1`, but bucket hardening settings were not yet enabled. Terraform describes these changes without applying them.

## Deliberate Limits

- Existing non-foundation APIs are not disabled or managed by this baseline.
- Existing IAM memberships are not copied into this repository. Optional IAM members require explicit approved operator input.
- No raw state, plan, tfvars, credentials, account identifiers, or principal identifiers are recorded.

Live staging validation remains pending until the required backend initialization, import, and saved-plan approval categories have completed.
