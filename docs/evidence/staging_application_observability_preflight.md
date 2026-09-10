# Staging Application And Observability Preflight

## Scope And Method

This evidence supports Issue #7 planning only. All cloud and Kubernetes checks used read-only commands. No application, controller, storage, network, budget, IAM, Terraform state, or other live resource was changed.

The reviewed repository revision is `fc7197b`. The approved target is intentionally referred to only as the staging target; no cloud project identifier is recorded here.

## Sanitized Runtime Baseline

| Check | Result |
| --- | --- |
| Active account available | Yes |
| Configured project matches the approved target | Yes |
| Foundation Terraform state boundary | Expected project, budget, and state-bucket addresses are present |
| Runtime Terraform state boundary | Contains only the approved cluster and required runtime API addresses |
| Cluster shape | One zonal Standard cluster, Regular release channel, one node pool |
| Node state | One Ready node |
| Node allocatable capacity | 940m CPU, 2799Mi memory, 110 pods |
| Current workload state | 10 system pods; no non-system workloads, PVCs, Ingresses, LoadBalancer Services, Jobs, or validation Pods |
| System declared requests | 518m CPU and 450Mi memory; one system container has no declared request |
| Installed controllers | Argo CD, Argo Rollouts, ingress-nginx, and kube-prometheus-stack are absent |
| Billable Compute inventory | One instance and one disk; no reserved addresses or forwarding rules |

The declared system requests are not a sufficient scheduling guarantee because one system container has no request. The deployment plan therefore reserves at least 700m CPU and 768Mi memory for GKE and system overhead rather than treating the remaining allocatable capacity as available to application workloads.

## Budget And IAM Boundaries

The budget was manually verified in the Console in the preceding runtime issue. The terminal Budget API path remains unresolved, so a fresh Console or API verification is a required precondition before any future capacity, storage, controller, or application action. This issue makes no budget change.

Repository Terraform guardrails prohibit public principals and broad billing administration. A fresh sanitized project-IAM read was not available from the current terminal context. A successful sanitized IAM verification is therefore also a required precondition before future live actions. This document does not claim a fresh live IAM result.

## Deterministic Stage Render

Dependencies were built in an isolated temporary copy with `helm dependency build --skip-refresh`. The dependency lock was unchanged. `helm lint` and `helm template` then completed successfully against the stage overlay without refreshing repositories or downloading updated chart indexes.

| Rendered object | Count |
| --- | ---: |
| Deployments | 12 |
| Rollouts | 1 |
| StatefulSets | 0 |
| Services | 14 |
| ServiceMonitors | 12 |
| PrometheusRules | 2 |
| PersistentVolumeClaims | 0 |
| Ingresses | 2 |
| Jobs and standalone Pods | 0 |
| AnalysisTemplates | 2 |
| AnalysisRuns | 0 |
| Workload replicas | 21 |
| Workload resource blocks | 0 |

The current stage render includes failure-injection resources and a two-replica load generator by default. The plan proposes keeping both disabled until a separately approved validation step. k6 manifests and validation Pods exist outside the rendered stage chart and currently include no suitable resource policy; they are not part of this deployment package.

Live staging validation remains pending.
