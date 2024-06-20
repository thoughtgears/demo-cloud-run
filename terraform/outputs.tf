output "docker_repository" {
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.platform.name}"
  description = "The Docker repository URL to use to build and push images"
}

output "service_accounts" {
  value = {
    for account_id, sa in local.service_accounts :
    sa.service => {
      email = google_service_account.this[account_id].email
    }
  }
  description = "A map of service accounts and their email addresses"
}

output "gcp_project_id" {
  value       = var.project_id
  description = "The GCP project ID"
}

output "gcp_region" {
  value       = var.region
  description = "The GCP region"
}