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
      image = "${var.region}-docker.pkg.dev/${var.project_id}/${each.value.repository_name}/${each.value.name}:latest"
      resources {
        limits = {
          cpu    = "1000m"
          memory = "256Mi"
        }
        cpu_idle = true
      }

      dynamic "env" {
        for_each = each.value.env
        content {
          name  = env.value.name
          value = env.value.value
        }
      }
    }

    scaling {
      max_instance_count = lookup(each.value, "max_instance_count", 1)
      min_instance_count = lookup(each.value, "min_instance_count", 0)
    }

    timeout                          = lookup(each.value, "timeout", "300s")
    service_account                  = google_service_account.this[each.key].email
    max_instance_request_concurrency = lookup(each.value, "concurrency", 80)
  }

  labels = merge(
    local.labels,
    {
      gcb-trigger-id     = google_cloudbuild_trigger.services[each.key].trigger_id,
      managed-by         = "gcp-cloud-build-deploy-cloud-run",
      gcp-trigger-region = var.region
    }
  )

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image
    ]
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