# Staging Runtime Terraform

This directory is an isolated, plan-first runtime layer for the existing staging foundation. Its GCS backend uses the existing state bucket with the separate `terraform/staging-runtime` prefix. It does not read, migrate, or alter foundation state.

## Scope

The only planned resources are two existing-project APIs (`compute.googleapis.com` and `container.googleapis.com`) and one zonal Standard GKE cluster named `online-shop-staging`. The default node pool has exactly one fixed `e2-medium` node. The configuration does not create a VPC, subnetwork, load balancer, NAT, disk, service account, IAM binding, budget, state bucket, GitOps component, Prometheus deployment, workload, traffic generator, secret, Artifact Registry repository, Cloud Run service, Scheduler job, logging resource, monitoring resource, or AI Operations integration.

Standard GKE is intentional. Autopilot is excluded because its observability defaults cannot meet this baseline's requirement to disable Managed Prometheus and collection components.

## Cost And Lifecycle

The cluster is an idle-capable but not zero-cost baseline: one node remains allocated continuously. GKE control-plane and node charges, boot-disk storage, and possible network charges apply. The project budget is an alert, not a hard spending cap. Logging and Monitoring collection components are empty and Managed Prometheus is disabled to avoid telemetry ingestion charges, but platform-generated data and future workloads can still create observability costs.

There is no scheduler or automatic shutdown/delete mechanism. Before any runtime apply, an operator must approve the expected idle window and a separate exact destroy plan. Deletion is supported because `deletion_protection` is disabled; use a separately reviewed `terraform destroy` plan after the runtime validation window. Destroy removes the cluster but deliberately keeps the two APIs enabled.

## Preconditions

Before an apply, confirm with explicit target-project commands that `compute.googleapis.com` and `container.googleapis.com` may be enabled and that the named existing network and subnetwork exist in the selected zone. This root must never be used to create those network resources.

## Plan-First Workflow

Do not run an apply without approval for the exact saved plan SHA-256.

```powershell
terraform init -reconfigure
terraform fmt -check -recursive
terraform validate
terraform plan -out=staging-runtime.tfplan
Get-FileHash -Algorithm SHA256 staging-runtime.tfplan
..\..\scripts\check-staging-runtime-plan.ps1 -PlanPath .\staging-runtime.tfplan
```

Plan and state artifacts are ignored. Do not commit or publish their contents.

## Validation

```powershell
terraform fmt -check -recursive
terraform validate
..\..\scripts\check-staging-runtime-guardrails.ps1
..\..\scripts\check-staging-runtime-plan.ps1 -PlanPath .\staging-runtime.tfplan
```

Live staging validation remains pending.
