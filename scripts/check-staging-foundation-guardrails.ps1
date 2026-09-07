Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$terraformDirectory = Join-Path $repositoryRoot "terraform"
$evidenceFile = Join-Path $repositoryRoot "docs\evidence\staging_foundation_terraform_preflight.md"

$terraformFiles = Get-ChildItem -Path $terraformDirectory -Filter "*.tf" -File -Recurse
if ($terraformFiles.Count -eq 0) {
  throw "No Terraform files found under $terraformDirectory."
}

$terraformText = ($terraformFiles | ForEach-Object { Get-Content -Raw -Path $_.FullName }) -join "`n"
$forbiddenResources = @(
  "google_container_cluster",
  "google_container_node_pool",
  "google_compute_disk",
  "google_compute_instance",
  "google_compute_router",
  "google_compute_router_nat",
  "google_compute_global_address",
  "google_compute_forwarding_rule",
  "google_compute_region_backend_service",
  "google_cloud_run",
  "google_cloud_scheduler",
  "google_secret_manager",
  "google_artifact_registry",
  "google_logging",
  "google_monitoring"
)

foreach ($forbiddenResource in $forbiddenResources) {
  if ($terraformText -match [regex]::Escape($forbiddenResource)) {
    throw "Cost-heavy or out-of-scope Terraform resource detected: $forbiddenResource"
  }
}

foreach ($forbiddenPrincipal in @("allUsers", "allAuthenticatedUsers", "projectOwners:", "projectEditors:", "projectViewers:")) {
  $assignmentPattern = "(?m)^\\s*member\\s*=\\s*`"$([regex]::Escape($forbiddenPrincipal))"
  if ($terraformText -match $assignmentPattern) {
    throw "Public or legacy pseudo-principal assignment detected in Terraform: $forbiddenPrincipal"
  }
}

if ($terraformText -match '(?m)^\s*role\s*=\s*"roles/billing\.admin"') {
  throw "Broad billing admin must not be represented in Terraform."
}

if ($terraformText -notmatch [regex]::Escape('projects = ["projects/${data.google_project.staging.number}"]')) {
  throw "Budget must be scoped to exactly the existing staging project number."
}

$gitVisibleFiles = @(
  & git -C $repositoryRoot ls-files
  & git -C $repositoryRoot diff --cached --name-only
  & git -C $repositoryRoot ls-files --others --exclude-standard
) | Sort-Object -Unique

$forbiddenArtifacts = $gitVisibleFiles | Where-Object {
  $_ -match "\.tfstate(\..+)?$" -or
  $_ -match "\.tfplan$" -or
  $_ -match "\.tfvars(\.json)?$"
}

if ($forbiddenArtifacts) {
  throw "Terraform state, plan, or tfvars artifact is visible to Git: $($forbiddenArtifacts[0])"
}

if (-not (Test-Path -LiteralPath $evidenceFile)) {
  throw "Missing staging preflight evidence file."
}

$evidenceText = Get-Content -Raw -Path $evidenceFile
if ($evidenceText -notmatch "Live staging validation remains pending") {
  throw "Evidence must state that live staging validation remains pending."
}

Write-Output "Staging foundation guardrails passed."
