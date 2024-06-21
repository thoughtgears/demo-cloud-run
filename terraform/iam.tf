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
    "ipam" = {
      account_id   = "run-ipam"
      service      = "ipam"
      display_name = "[RUN] IPAM"
      description  = "Service account for IPAM Cloud Run service"
    }
    "backend" = {
      account_id   = "run-backend"
      service      = "backend"
      display_name = "[RUN] Backend"
      description  = "Service account for backend Cloud Run service"
    }
    "frontend" = {
      account_id   = "ae-frontend"
      service      = "frontend"
      display_name = "[AE] Frontend"
      description  = "Service account for frontend App engine service"
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

resource "google_project_iam_member" "ipam_firestore" {
  project = var.project_id
  member  = "serviceAccount:${google_service_account.this["ipam"].email}"
  role    = "roles/datastore.user"
}

resource "google_organization_iam_member" "ipam_viewer" {
  org_id = var.organization_id
  member = "serviceAccount:${google_service_account.this["ipam"].email}"
  role   = "roles/viewer"
}