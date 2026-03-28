resource "google_secret_manager_secret_iam_member" "secret_access" {
  for_each = var.secret_ids

  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.service_account_email}"
}

resource "google_storage_bucket_iam_member" "job_writer" {
  bucket = var.bucket_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.service_account_email}"
}

data "google_artifact_registry_repository" "this" {
  location      = var.region
  repository_id = var.artifact_registry_repo
  project       = var.project_id
}

resource "google_artifact_registry_repository_iam_member" "job_puller" {
  project    = data.google_artifact_registry_repository.this.project
  location   = data.google_artifact_registry_repository.this.location
  repository = data.google_artifact_registry_repository.this.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${var.service_account_email}"
}
