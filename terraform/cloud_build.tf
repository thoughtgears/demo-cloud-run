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

resource "google_secret_manager_secret_version" "github_token_secret_version" {
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
      oauth_token_secret_version = google_secret_manager_secret_version.github_token_secret_version.id
    }
  }
}

resource "google_cloudbuildv2_repository" "demo_cloud_run" {
  project           = var.project_id
  location          = var.region
  name              = local.github_repo
  parent_connection = google_cloudbuildv2_connection.github_thoughtgears.name
  remote_uri        = "https://github.com/${local.github_owner}/${local.github_repo}.git"
}

/*
  Setup the Cloud Build trigger
 */
resource "google_cloudbuild_trigger" "this" {
  project  = var.project_id
  location = var.region
  name     = "${local.github_repo}-deploy"

  substitutions = {
    _SPACELIFT_API_URL = "https://thoughtgears.app.spacelift.io/graphql"
  }

  repository_event_config {
    repository = google_cloudbuildv2_repository.demo_cloud_run.id
    push {
      branch = "^main$"
    }
  }

  service_account    = google_service_account.build_demo_cloud_build.id
  filename           = "cloudbuild.yaml"
  include_build_logs = "INCLUDE_BUILD_LOGS_WITH_STATUS"

  depends_on = [
    google_project_iam_member.build_demo_cloud_build_act_as,
    google_project_iam_member.build_demo_cloud_build_app_engine_admin,
    google_project_iam_member.build_demo_cloud_build_artifact_registry_admin,
    google_project_iam_member.build_demo_cloud_build_logs_writer,
    google_project_iam_member.build_demo_cloud_build_run_admin,
    google_project_iam_member.build_demo_cloud_build_secret_manager_access
  ]
}
