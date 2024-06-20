locals {
  # You will access these service accounts in iam bindings and other resources
  # by using the `google_service_account.this["discovery"]` reference.
  service_accounts = {
    "discovery" = {
      account_id   = "run-discovery"
      service      = "discovery"
      display_name = "[RUN] Discovery"
      description  = "Service account for discovery Cloud Run service"
    }
  }
}

resource "google_service_account" "this" {
  for_each = local.service_accounts

  project      = var.project_id
  account_id   = each.value.account_id
  display_name = each.value.display_name
  description  = each.value.description
}

# Set permissions for the discovery cloud run service
resource "google_project_iam_member" "discovery_firestore" {
  project = var.project_id
  member  = "serviceAccount:${google_service_account.this["discovery"].email}"
  role    = "roles/datastore.user"
}