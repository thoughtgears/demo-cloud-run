resource "google_artifact_registry_repository" "platform" {
  project       = var.project_id
  location      = var.region
  repository_id = "platform"
  format        = "DOCKER"

  labels = local.labels
}
