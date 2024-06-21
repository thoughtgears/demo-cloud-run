resource "google_app_engine_application" "frontend" {
  project       = var.project_id
  location_id   = var.region
  database_type = "CLOUD_FIRESTORE"

  iap {
    oauth2_client_id     = google_iap_client.client.client_id
    oauth2_client_secret = google_iap_client.client.secret
  }

  depends_on = [google_project_service.this["appengine.googleapis.com"]]
}

resource "google_project_service" "iap" {
  project = var.project_id
  service = "iap.googleapis.com"
}

resource "google_iap_brand" "brand" {
  project           = google_project_service.iap.project
  support_email     = "support@thoughtgears.co.uk"
  application_title = "Cloud IAP protected Application"
}

import {
  id = "projects/${var.project_id}/brands/105849508967"
  to = google_iap_brand.brand
}

resource "google_iap_client" "client" {
  display_name = "Default Client"
  brand        = google_iap_brand.brand.name
}

resource "google_iap_web_iam_member" "member" {
  project = google_project_service.iap.project
  role    = "roles/iap.httpsResourceAccessor"
  member  = "domain:${local.github_owner}.co.uk"
}
