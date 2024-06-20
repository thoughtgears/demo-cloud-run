resource "google_firestore_database" "database" {
  project     = var.project_id
  name        = "(default)"
  location_id = "eur3"
  type        = "FIRESTORE_NATIVE"
}

resource "google_firestore_backup_schedule" "weekly-backup" {
  project  = var.project_id
  database = google_firestore_database.database.name

  retention = "8467200s" // 14 weeks (maximum possible retention)

  weekly_recurrence {
    day = "SUNDAY"
  }
}