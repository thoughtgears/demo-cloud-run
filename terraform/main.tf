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
      repository_name    = "platform"
      max_instance_count = 1
      env = {
        "GCP_PROJECT_ID" = {
          name  = "GCP_PROJECT_ID"
          value = var.project_id
        },
        "GCP_REGION" = {
          name  = "GCP_REGION"
          value = var.region
        }
      }
    }
    "ipam" = {
      name            = "ipam"
      repository_name = "platform"
      env = {
        "GCP_PROJECT_ID" = {
          name  = "GCP_PROJECT_ID"
          value = var.project_id
        },
        "GCP_REGION" = {
          name  = "GCP_REGION"
          value = var.region
        },
        "GCP_ORGANIZATION_ID" = {
          name  = "GCP_ORGANIZATION_ID"
          value = var.organization_id
        }
      }
    }
    "backend" = {
      name            = "backend"
      repository_name = "demos"
    }
  }
}

resource "google_project_service" "this" {
  for_each = toset(local.service_apis)
  project  = var.project_id
  service  = each.value
}