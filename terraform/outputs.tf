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
}