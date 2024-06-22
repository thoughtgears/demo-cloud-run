locals {
  service_apis = [
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com",
    "eventarc.googleapis.com",
    "firestore.googleapis.com",
    "iap.googleapis.com",
    "appengine.googleapis.com",
  ]

  labels = {
    "terraform"            = "true"
    "terraform-repository" = "demo-cloud-run"
    "terraform-owner"      = "thoughtgears"
  }

  company     = "thoughtgears"
  github_repo = "demo-cloud-run"

  services = {
    "discovery" = {
      name               = "discovery"
      repository_name    = "demos"
      max_instance_count = 1
    }
    "ipam" = {
      name            = "ipam"
      repository_name = "platform"
    }
    "backend" = {
      name            = "backend"
      repository_name = "platform"
    }
  }
}

resource "google_project_service" "this" {
  for_each = toset(local.service_apis)
  project  = var.project_id
  service  = each.value
}