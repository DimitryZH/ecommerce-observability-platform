variable "project_id" {
  description = "Existing staging GCP project managed by this configuration."
  type        = string
  default     = "sre-platform-staging-507220"
}

variable "region" {
  description = "GCP provider region."
  type        = string
  default     = "us-central1"
}

variable "state_bucket_location" {
  description = "Existing state bucket location."
  type        = string
  default     = "US-CENTRAL1"
}

variable "billing_account_id" {
  description = "Operator-supplied billing account ID used only for importing and managing the existing budget."
  type        = string
  sensitive   = true
}

variable "foundation_labels" {
  description = "Existing staging project labels."
  type        = map(string)
  default = {
    "cost-profile" = "demo"
    environment    = "staging"
    platform       = "sre-platform"
    scope          = "foundation"
  }
}

variable "budget_threshold_rules" {
  description = "Operator-supplied existing budget thresholds. Keep in an uncommitted tfvars file."
  type = list(object({
    threshold_percent = number
    spend_basis       = string
  }))
}

variable "project_iam_members" {
  description = "Optional, non-authoritative project IAM members. Keep identities in uncommitted operator input."
  type = map(object({
    role   = string
    member = string
  }))
  default = {}
}
