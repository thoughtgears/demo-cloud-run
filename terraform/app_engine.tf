resource "google_app_engine_application" "frontend" {
  project       = var.project_id
  location_id   = "europe-west"
  database_type = "CLOUD_FIRESTORE"

  iap {
    oauth2_client_id     = google_iap_client.client.client_id
    oauth2_client_secret = google_iap_client.client.secret
  }

  depends_on = [google_project_service.this["appengine.googleapis.com"]]
}

import {
  id = var.project_id
  to = google_app_engine_application.frontend
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

resource "google_iap_client" "client" {
  display_name = "Default Client"
  brand        = google_iap_brand.brand.name
}

resource "google_iap_web_iam_member" "member" {
  project = google_project_service.iap.project
  role    = "roles/iap.httpsResourceAccessor"
  member  = "domain:${local.company}.co.uk"
}
