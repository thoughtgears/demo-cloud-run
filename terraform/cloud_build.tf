/*
  Create the secrets to support the Cloud Build connection to GitHub
  INFO: The pat is a classic pat with no expiration and access to all
  repositories, it has repo, red:user and read:org
  https://cloud.google.com/build/docs/automating-builds/github/connect-repo-github?generation=2nd-gen
 */
resource "google_secret_manager_secret" "github_pat_thoughtgears" {
  project   = var.project_id
  secret_id = "github-pat-${local.company}"

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

/*
  Create the Cloud Build connection to GitHub with the help of the PAT
  This has to be v2 since the v1 dont support programmatic creation
 */
resource "google_cloudbuildv2_connection" "github_thoughtgears" {
  project  = var.project_id
  location = var.region
  name     = "github-${local.company}"

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
  remote_uri        = "https://github.com/${local.company}/${local.github_repo}.git"
}

/*
  Setup the Cloud Build service account and the permissions required for the build
  INFO: These are broader then needed, but for the purpose of the demo, we will give
  the service account admin, in the real world, you would want to limit these permissions
 */
resource "google_service_account" "build_demo_cloud_build" {
  project    = var.project_id
  account_id = "build-demo-cloud-run"
}

resource "google_project_iam_member" "build_demo_cloud_build_act_as" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.build_demo_cloud_build.email}"
}

resource "google_project_iam_member" "build_demo_cloud_build_logs_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.build_demo_cloud_build.email}"
}

resource "google_project_iam_member" "build_demo_cloud_build_artifact_registry_admin" {
  project = var.project_id
  role    = "roles/artifactregistry.admin"
  member  = "serviceAccount:${google_service_account.build_demo_cloud_build.email}"
}

resource "google_project_iam_member" "build_demo_cloud_build_run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.build_demo_cloud_build.email}"
}

resource "google_project_iam_member" "build_demo_cloud_build_app_engine_admin" {
  project = var.project_id
  role    = "roles/appengine.appAdmin"
  member  = "serviceAccount:${google_service_account.build_demo_cloud_build.email}"
}

resource "google_project_iam_member" "build_demo_cloud_build_secret_manager_access" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.build_demo_cloud_build.email}"
}

resource "google_project_iam_member" "build_demo_cloud_build_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.build_demo_cloud_build.email}"
}

/*
  Setup the Cloud Build Triggers to deploy the Cloud Run services
  INFO: The trigger will be triggered on a push to the main branch
  and will use the cloudbuild.yaml file in each of the services directories
  to deploy the services.

  If any of the files altered in the commit pass the ignoredFiles filter and
  includedFiles is empty, then as far as this filter is concerned, we should
  trigger the build. If any of the files altered in the commit pass the ignoredFiles
  filter and includedFiles is not empty, then we make sure that at least one of
  those files matches a includedFiles glob. If not, then we do not trigger a build.
 */
locals {
  global_substitutions = {
    _SPACELIFT_API_URL = "https://thoughtgears.app.spacelift.io/graphql"
  }
}

resource "google_cloudbuild_trigger" "services" {
  for_each = local.services

  project  = var.project_id
  location = var.region
  name     = "${each.value.name}-deploy"

  substitutions = merge(local.global_substitutions, lookup(each.value, "substitutions", {}))

  ignored_files = [
    "README.md",
    "LICENSE",
    ".gitignore",
    "docker-compose.yml",
    "Makefile",
    "pyproject.toml",
    "terraform/**",
    ".github/**",
    "firebase/**",
    "emulator/**",
    "resources/**"
  ]

  included_files = [
    "services/${each.value.name}/**"
  ]

  repository_event_config {
    repository = google_cloudbuildv2_repository.demo_cloud_run.id
    push {
      branch = "^main$"
    }
  }

  service_account    = google_service_account.build_demo_cloud_build.id
  filename           = "services/${each.value.name}/cloudbuild.yaml"
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

/*
  Build trigger for a custom build step that we should use in our Service runs
  This will build a custom docker container and push to the Artifact Registry
  platform repo that can be reused in the services cloud build steps
 */
resource "google_cloudbuild_trigger" "poll_spacelift" {
  project  = var.project_id
  location = var.region
  name     = "poll-spacelift-deploy"

  ignored_files = [
    "README.md",
    "LICENSE",
    ".gitignore",
    "docker-compose.yml",
    "Makefile",
    "pyproject.toml",
    "terraform/**",
    ".github/**",
    "firebase/**",
    "emulator/**",
    "services/**"
  ]

  included_files = [
    "resources/cloud_build/poll_spacelift/**"
  ]

  repository_event_config {
    repository = google_cloudbuildv2_repository.demo_cloud_run.id
    push {
      branch = "^main$"
    }
  }

  service_account    = google_service_account.build_demo_cloud_build.id
  filename           = "resources/cloud_build/poll_spacelift/cloudbuild.yaml"
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
