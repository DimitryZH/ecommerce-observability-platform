param(
  [Parameter(Mandatory = $true)]
  [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
  [string]$PlanPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$resolvedPlanPath = (Resolve-Path -LiteralPath $PlanPath).Path
$runtimeDirectory = Join-Path $repositoryRoot "terraform\runtime"
$planJson = & terraform "-chdir=$runtimeDirectory" show -json $resolvedPlanPath | ConvertFrom-Json
$changes = @($planJson.resource_changes)
$allowedAddresses = @(
  'google_container_cluster.staging',
  'google_project_service.runtime["compute.googleapis.com"]',
  'google_project_service.runtime["container.googleapis.com"]'
)

foreach ($change in $changes) {
  if ($change.address -notin $allowedAddresses) {
    throw "Unexpected planned resource: $($change.address)"
  }

  if ($change.change.actions -notcontains "create") {
    throw "Only create actions are permitted in the initial runtime plan: $($change.address)"
  }
}

if (($changes | Where-Object { $_.address -eq 'google_container_cluster.staging' }).Count -ne 1) {
  throw "The plan must contain exactly one staging cluster."
}

if (($changes | Where-Object { $_.address -like 'google_project_service.runtime*' }).Count -ne 2) {
  throw "The plan must contain exactly the two approved runtime APIs."
}

Write-Output "Staging runtime plan guardrails passed."
