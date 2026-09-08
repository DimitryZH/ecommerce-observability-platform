output "cluster_name" {
  description = "Name of the planned minimal staging cluster."
  value       = google_container_cluster.staging.name
}

output "cluster_location" {
  description = "Zonal location of the planned minimal staging cluster."
  value       = google_container_cluster.staging.location
}
