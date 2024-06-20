locals {
  service_apis = [
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com",
    "eventarc.googleapis.com",
    "firestore.googleapis.com",
  ]

  labels = {
    "terraform"            = "true"
    "terraform-repository" = "demo-cloud-run"
    "terraform-owner"      = "thoughtgears"
  }
}

resource "google_project_service" "this" {
  for_each = toset(local.service_apis)
  project  = var.project_id
  service  = each.value
}