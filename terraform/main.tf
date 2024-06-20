locals {
  service_apis = [
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com",
    "eventarc.googleapis.com",
  ]
}

resource "google_project_service " "this" {
  for_each = toset(local.service_apis)
  project  = var.project_id
  service  = each.value
}