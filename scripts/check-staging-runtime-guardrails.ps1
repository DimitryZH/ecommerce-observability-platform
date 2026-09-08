Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$runtimeDirectory = Join-Path $repositoryRoot "terraform\runtime"
$evidenceFile = Join-Path $repositoryRoot "docs\evidence\staging_runtime_terraform_plan.md"
$terraformFiles = Get-ChildItem -Path $runtimeDirectory -Filter "*.tf" -File -Recurse

if ($terraformFiles.Count -eq 0) {
  throw "No runtime Terraform files found under $runtimeDirectory."
}

$terraformText = ($terraformFiles | ForEach-Object { Get-Content -Raw -Path $_.FullName }) -join "`n"
$forbiddenTokens = @(
  "google_billing_budget",
  "google_project_iam",
  "google_storage_bucket",
  "google_compute_network",
  "google_compute_subnetwork",
  "google_compute_router",
  "google_compute_router_nat",
  "google_compute_forwarding_rule",
  "google_container_node_pool",
  "kubernetes_",
  "helm_release",
  "argocd",
  "google_cloud_run",
  "google_cloud_scheduler",
  "google_secret_manager",
  "google_artifact_registry",
  "google_logging",
  "google_monitoring"
)

foreach ($token in $forbiddenTokens) {
  if ($terraformText -match [regex]::Escape($token)) {
    throw "Out-of-scope runtime Terraform token detected: $token"
  }
}

if ($terraformText -notmatch 'resource\s+"google_container_cluster"\s+"staging"') {
  throw "The runtime baseline must define exactly the approved staging cluster."
}

if ($terraformText -notmatch '(?m)^\s*initial_node_count\s*=\s*1\s*$') {
  throw "The runtime baseline must retain exactly one initial node."
}

if ($terraformText -notmatch 'managed_prometheus\s*\{\s*enabled\s*=\s*false\s*\}') {
  throw "Managed Prometheus must remain disabled."
}

if ($terraformText -notmatch 'logging_config\s*\{\s*enable_components\s*=\s*\[\]\s*\}') {
  throw "GKE logging collection components must remain empty."
}

if ($terraformText -notmatch 'monitoring_config\s*\{\s*enable_components\s*=\s*\[\]') {
  throw "GKE monitoring collection components must remain empty."
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
  throw "Missing runtime plan evidence file."
}

$evidenceText = Get-Content -Raw -Path $evidenceFile
if ($evidenceText -notmatch "Live staging validation remains pending") {
  throw "Evidence must state that live staging validation remains pending."
}

Write-Output "Staging runtime guardrails passed."
