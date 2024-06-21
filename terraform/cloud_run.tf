locals {
  services = [
    "discovery",
    "ipam",
    "backend"
  ]
}

# Just used for scaffolding service, not to manage the service
# We manage the service in cloud build
resource "google_cloud_run_v2_service" "this" {
  for_each = toset(local.services)

  project  = var.project_id
  location = var.region
  name     = each.value
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    containers {
      image = "us-docker.pkg.dev/cloudrun/container/hello"
    }
  }

  lifecycle {
    ignore_changes = all
  }
}
