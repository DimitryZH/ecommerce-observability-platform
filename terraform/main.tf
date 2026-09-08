provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google" {
  alias                 = "budget"
  project               = var.project_id
  region                = var.region
  billing_project       = var.project_id
  user_project_override = true
}

data "google_project" "staging" {
  project_id = var.project_id
}

locals {
  approved_foundation_apis = toset([
    "billingbudgets.googleapis.com",
    "serviceusage.googleapis.com",
    "storage.googleapis.com",
  ])
}

resource "google_project" "staging" {
  project_id      = var.project_id
  name            = data.google_project.staging.name
  billing_account = var.billing_account_id
  labels          = var.foundation_labels

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      folder_id,
      org_id,
    ]
  }
}

resource "google_project_service" "foundation" {
  for_each = local.approved_foundation_apis

  project                    = var.project_id
  service                    = each.value
  disable_on_destroy         = false
  disable_dependent_services = false
}

resource "google_storage_bucket" "terraform_state" {
  name                        = "sre-platform-staging-507220-tf-state"
  location                    = var.state_bucket_location
  labels                      = var.foundation_labels
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  retention_policy {
    retention_period = 2592000
  }

  soft_delete_policy {
    retention_duration_seconds = 604800
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [lifecycle_rule]
  }
}

resource "google_billing_budget" "staging" {
  provider = google.budget

  billing_account = var.billing_account_id
  display_name    = "sre-platform-staging-budget-100-cad"

  budget_filter {
    projects = ["projects/${data.google_project.staging.number}"]
  }

  amount {
    specified_amount {
      currency_code = "CAD"
      units         = "100"
    }
  }

  dynamic "threshold_rules" {
    for_each = var.budget_threshold_rules

    content {
      threshold_percent = threshold_rules.value.threshold_percent
      spend_basis       = threshold_rules.value.spend_basis
    }
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = all
  }
}

resource "google_project_iam_member" "optional_baseline" {
  for_each = var.project_iam_members

  project = var.project_id
  role    = each.value.role
  member  = each.value.member

  lifecycle {
    precondition {
      condition = (
        each.value.role != "roles/billing.admin" &&
        !contains(["allUsers", "allAuthenticatedUsers"], each.value.member)
      )
      error_message = "The staging IAM baseline must not grant billing.admin or public principals."
    }
  }
}
