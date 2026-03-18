data "google_project" "this" {
  project_id = var.project_id
}

resource "google_project_service" "cloudscheduler_api" {
  project = var.project_id
  service = "cloudscheduler.googleapis.com"
}

resource "google_storage_bucket" "this" {
  name     = var.bucket_name
  location = var.location
  project  = var.project_id

  force_destroy = true
}

locals {
  job_service_account = "${data.google_project.this.number}-compute@developer.gserviceaccount.com"
  job_image_base      = "${var.region}-docker.pkg.dev/${var.project_id}/${var.artifact_registry_repo}/spotify-history"
  job_image           = var.cloud_run_image_digest != "" ? "${local.job_image_base}@${var.cloud_run_image_digest}" : "${local.job_image_base}:${var.cloud_run_image_tag}"
  gcs_mount_path      = "/mnt/spotify-history"
}

resource "google_cloud_run_v2_job" "spotify_history" {
  name     = var.cloud_run_job_name
  location = var.region
  project  = var.project_id

  template {
    template {
      max_retries = 0
      service_account = local.job_service_account

      volumes {
        name = "gcs-bucket"
        gcs {
          bucket = google_storage_bucket.this.name
        }
      }

      containers {
        image = local.job_image

        volume_mounts {
          name       = "gcs-bucket"
          mount_path = local.gcs_mount_path
        }

        env {
          name  = "GCP_PROJECT_ID"
          value = var.project_id
        }
        env {
          name  = "GCS_BUCKET"
          value = google_storage_bucket.this.name
        }
        env {
          name  = "GCS_MOUNT_PATH"
          value = local.gcs_mount_path
        }
        env {
          name = "SPOTIFY_TOKEN_JSON"
          value_source {
            secret_key_ref {
              secret  = "projects/${var.project_id}/secrets/spotify-token-json"
              version = "latest"
            }
          }
        }
        env {
          name = "SPOTIFY_CLIENT_ID"
          value_source {
            secret_key_ref {
              secret  = "projects/${var.project_id}/secrets/spotify-client-id"
              version = "latest"
            }
          }
        }
        env {
          name = "SPOTIFY_CLIENT_SECRET"
          value_source {
            secret_key_ref {
              secret  = "projects/${var.project_id}/secrets/spotify-client-secret"
              version = "latest"
            }
          }
        }
        env {
          name = "SPOTIFY_REDIRECT_URI"
          value_source {
            secret_key_ref {
              secret  = "projects/${var.project_id}/secrets/spotify-redirect-uri"
              version = "latest"
            }
          }
        }
      }
    }
  }

  depends_on = [
    google_secret_manager_secret_iam_member.spotify_token_json,
    google_secret_manager_secret_iam_member.spotify_client_id,
    google_secret_manager_secret_iam_member.spotify_client_secret,
    google_secret_manager_secret_iam_member.spotify_redirect_uri,
    google_storage_bucket_iam_member.job_writer,
    google_artifact_registry_repository_iam_member.job_puller,
  ]

  lifecycle {
    ignore_changes = [launch_stage]
  }
}

resource "google_cloud_scheduler_job" "job" {
  name             = "schedule-job"
  description      = "test http job"
  schedule         = "*/15 * * * *"
  attempt_deadline = "320s"
  region           = var.scheduler_region
  project          = var.project_id

  retry_config {
    retry_count = 3
  }

  http_target {
    http_method = "POST"
    uri         = "https://${google_cloud_run_v2_job.spotify_history.location}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${data.google_project.this.number}/jobs/${google_cloud_run_v2_job.spotify_history.name}:run"

    oauth_token {
      service_account_email = local.job_service_account
    }
  }

  depends_on = [
    google_project_service.cloudscheduler_api,
    google_cloud_run_v2_job.spotify_history,
    google_cloud_run_v2_job_iam_binding.binding,
  ]
}

resource "google_secret_manager_secret_iam_member" "spotify_token_json" {
  secret_id = "projects/${var.project_id}/secrets/spotify-token-json"
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${local.job_service_account}"
}

resource "google_secret_manager_secret_iam_member" "spotify_client_id" {
  secret_id = "projects/${var.project_id}/secrets/spotify-client-id"
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${local.job_service_account}"
}

resource "google_secret_manager_secret_iam_member" "spotify_client_secret" {
  secret_id = "projects/${var.project_id}/secrets/spotify-client-secret"
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${local.job_service_account}"
}

resource "google_secret_manager_secret_iam_member" "spotify_redirect_uri" {
  secret_id = "projects/${var.project_id}/secrets/spotify-redirect-uri"
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${local.job_service_account}"
}

# GCS: objectAdmin for FUSE mount read/write and API uploads
resource "google_storage_bucket_iam_member" "job_writer" {
  bucket = google_storage_bucket.this.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${local.job_service_account}"
}

# Artifact Registry: so the job can pull the image
data "google_artifact_registry_repository" "spotify_history" {
  location      = var.region
  repository_id = var.artifact_registry_repo
  project       = var.project_id
}

resource "google_artifact_registry_repository_iam_member" "job_puller" {
  project    = data.google_artifact_registry_repository.spotify_history.project
  location   = data.google_artifact_registry_repository.spotify_history.location
  repository = data.google_artifact_registry_repository.spotify_history.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${local.job_service_account}"
}

resource "google_cloud_run_v2_job_iam_binding" "binding" {
  project  = var.project_id
  location = google_cloud_run_v2_job.spotify_history.location
  name     = google_cloud_run_v2_job.spotify_history.name
  role     = "roles/run.invoker"
  members  = ["serviceAccount:${local.job_service_account}"]
}
