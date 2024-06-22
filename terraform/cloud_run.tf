# Just used for scaffolding service, not to manage the service
# We manage the service in cloud build
resource "google_cloud_run_v2_service" "this" {
  for_each = local.services

  project  = var.project_id
  location = var.region
  name     = each.key
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


resource "google_cloud_run_v2_service_iam_member" "frontend_to_backend" {
  project  = google_cloud_run_v2_service.this["backend"].project
  location = google_cloud_run_v2_service.this["backend"].location
  name     = google_cloud_run_v2_service.this["backend"].name
  member   = "serviceAccount:${google_service_account.this["frontend"].email}"
  role     = "roles/run.invoker"
}

resource "google_cloud_run_v2_service_iam_member" "frontend_to_discovery" {
  project  = google_cloud_run_v2_service.this["discovery"].project
  location = google_cloud_run_v2_service.this["discovery"].location
  name     = google_cloud_run_v2_service.this["discovery"].name
  member   = "serviceAccount:${google_service_account.this["frontend"].email}"
  role     = "roles/run.invoker"
}