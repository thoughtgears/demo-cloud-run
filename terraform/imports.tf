import {
  id = "projects/${var.project_id}/locations/${var.region}/repositories/platform"
  to = google_artifact_registry_repository.platform
}

import {
  id = "projects/${var.project_id}/serviceAccounts/run-discovery@thoughtgears-showcase-17657.iam.gserviceaccount.com"
  to = google_service_account.this["discovery"]
}

import {
  id = "${var.project_id} roles/datastore.user serviceAccount:run-discovery@thoughtgears-showcase-17657.iam.gserviceaccount.com"
  to = google_project_iam_member.discovery_firestore
}