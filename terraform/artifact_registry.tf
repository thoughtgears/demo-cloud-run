# Generate a new repository in Artifact Registry for our platform services
resource "google_artifact_registry_repository" "platform" {
  project       = var.project_id
  location      = var.region
  repository_id = "platform"
  format        = "DOCKER"

  labels = local.labels
}

# Create a new repository for the demo Cloud Run service
resource "google_artifact_registry_repository" "demo_cloud_run" {
  project       = var.project_id
  location      = var.region
  repository_id = "demos"
  format        = "DOCKER"
}