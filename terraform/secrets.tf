locals {
  secrets = {
    "spacelift-api-key"    = var.spacelift_api_key
    "spacelift-api-key-id" = var.spacelift_api_key_id
    "spacelift-stack-id"   = var.spacelift_stack_id
  }
}

resource "google_secret_manager_secret" "this" {
  for_each = local.secrets

  project   = var.project_id
  secret_id = each.key

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "this" {
  for_each = local.secrets

  secret      = google_secret_manager_secret.this[each.key].id
  secret_data = each.value
}