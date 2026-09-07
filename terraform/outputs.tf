output "staging_project_id" {
  description = "The existing staging project under Terraform control after import."
  value       = google_project.staging.project_id
}

output "state_bucket_name" {
  description = "The existing remote state bucket managed by this configuration."
  value       = google_storage_bucket.terraform_state.name
}
