resource "google_app_engine_application" "frontend" {
  project       = var.project_id
  location_id   = var.region
  database_type = "CLOUD_FIRESTORE"

  iap {
    oauth2_client_id     = google_iap_client.client.client_id
    oauth2_client_secret = google_iap_client.client.secret
  }
}

resource "google_iap_brand" "brand" {
  project           = var.project_id
  support_email     = "support@thoughtgears.co.uk"
  application_title = "Thoughtgears application"
}

resource "google_iap_client" "client" {
  display_name = "Default Client"
  brand        = google_iap_brand.brand.name
}

resource "google_iap_web_iam_member" "member" {
  project = var.project_id
  role    = "roles/iap.httpsResourceAccessor"
  member  = "domain:${local.github_owner}.co.uk"
}
