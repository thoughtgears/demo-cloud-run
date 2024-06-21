/*
  Setup the Cloud Build connection to GitHub
 */
resource "google_secret_manager_secret" "github_pat_thoughtgears" {
  project   = var.project_id
  secret_id = "github-pat-${local.github_owner}"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "github-token-secret-version" {
  secret      = google_secret_manager_secret.github_pat_thoughtgears.id
  secret_data = var.github_pat
}

data "google_iam_policy" "p4sa-secretAccessor" {
  binding {
    role    = "roles/secretmanager.secretAccessor"
    members = ["serviceAccount:service-${var.project_number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"]
  }
}

resource "google_secret_manager_secret_iam_policy" "policy" {
  project     = var.project_id
  secret_id   = google_secret_manager_secret.github_pat_thoughtgears.secret_id
  policy_data = data.google_iam_policy.p4sa-secretAccessor.policy_data
}

resource "google_cloudbuildv2_connection" "github_thoughtgears" {
  project  = var.project_id
  location = var.region
  name     = "github-${local.github_owner}"

  github_config {
    app_installation_id = var.github_app_installation_id
    authorizer_credential {
      oauth_token_secret_version = google_secret_manager_secret_version.github-token-secret-version.id
    }
  }
}

resource "google_cloudbuildv2_repository" "demo-cloud-run" {
  project           = var.project_id
  location          = var.region
  name              = local.github_repo
  parent_connection = google_cloudbuildv2_connection.github_thoughtgears.name
  remote_uri        = "https://github.com/${local.github_owner}/${local.github_repo}.git"
}

/*
  Setup the Cloud Build trigger for the discovery service
 */

