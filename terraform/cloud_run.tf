locals {
  services = [
    "discovery",
    "ipam",
    "backend"
  ]
}

resource "google_cloud_run_v2_service" "this" {
  for_each = toset(local.services)

  project  = var.project_id
  location = var.region
  name     = each.value

  template {
    spec {
      containers {
        image = "us-docker.pkg.dev/cloudrun/container/hello"
      }
    }
  }

  lifecycle {
    ignore_changes = all
  }
}

import {
  id = "projects/${var.project_id}/locations/${var.region}/services/discovery"
  to = google_cloud_run_v2_service.this["discovery"]
}

import {
  id = "projects/${var.project_id}/locations/${var.region}/services/ipam"
  to = google_cloud_run_v2_service.this["ipam"]
}