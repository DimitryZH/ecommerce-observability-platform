# Staging Foundation Terraform

This directory adopts the existing staging foundation. It is intentionally limited to the project boundary, billing budget, approved foundation APIs, state bucket hardening, labels, and an optional non-authoritative project IAM baseline.

It does not define GKE, node pools, disks, GitOps, Prometheus, application workloads, traffic generators, load balancers, NAT, Cloud Run, Scheduler, secrets, Artifact Registry, or logging and monitoring ingestion resources.

## Remote State

The backend is the existing bucket `sre-platform-staging-507220-tf-state` with prefix `terraform/staging-foundation`. The backend intentionally starts with empty state; a pre-existing obsolete local state was discarded without inspection and must never be migrated into this foundation.

## Operator Inputs

Never commit account identifiers, principal identifiers, state, plan files, or tfvars. Supply `billing_account_id` and the verified existing budget thresholds from an ignored local tfvars file or the operator environment.

`project_iam_members` defaults to an empty map. It is deliberately non-authoritative: no IAM member is added, removed, or imported unless an explicitly approved local input provides it.

The `google.budget` provider alias scopes quota-project attribution to Billing Budgets API calls only. The default provider remains free of that override so existing project reads do not require unrelated API activation.

## Import-First Workflow

Run every command only after its required approval category.

1. Initialize the empty backend after the backend/state-init approval:

   ```powershell
   terraform init -reconfigure -migrate-state=false
   ```

2. Import existing resources. Replace every redacted placeholder locally; do not put those values in this repository.

   ```powershell
   terraform import -var="billing_account_id=<redacted>" google_project.staging sre-platform-staging-507220
   terraform import google_project_service.foundation["billingbudgets.googleapis.com"] sre-platform-staging-507220/billingbudgets.googleapis.com
   terraform import google_project_service.foundation["serviceusage.googleapis.com"] sre-platform-staging-507220/serviceusage.googleapis.com
   terraform import google_project_service.foundation["storage.googleapis.com"] sre-platform-staging-507220/storage.googleapis.com
   terraform import google_storage_bucket.terraform_state sre-platform-staging-507220-tf-state
   terraform import -var="billing_account_id=<redacted>" google_billing_budget.staging "billingAccounts/<redacted>/budgets/<redacted>"
   ```

3. Create a saved plan only after imports and its separate approval. Keep it outside Git, hash it with SHA-256, review it, and request an explicit plan-apply approval before any apply.

   ```powershell
   terraform plan -out=staging-foundation.tfplan
   Get-FileHash -Algorithm SHA256 staging-foundation.tfplan
   ```

If the budget import reports a local Application Default Credentials quota-project prerequisite, stop. Use the scoped `google.budget` provider alias only after separate approval; do not enable unrelated APIs or change credentials.

## Expected Changes After Import

The project, budget, and approved APIs should converge without change when operator inputs exactly match the existing budget thresholds. The state bucket will propose the following hardening changes: uniform bucket-level access, public access prevention, versioning, a 30-day retention policy, a 7-day soft-delete policy, and foundation labels.

Versioning and retention can retain small additional state-object storage. No compute, networking, workload, or telemetry ingestion cost is introduced.

## Validation

```powershell
terraform fmt -check -recursive
terraform validate
.\scripts\check-staging-foundation-guardrails.ps1
```

Live staging validation remains pending until backend initialization, imports, a reviewed saved plan, and the required approval categories are completed.
