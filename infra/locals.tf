locals {
  job_service_account = "${data.google_project.this.number}-compute@developer.gserviceaccount.com"
  job_image_base      = "${var.region}-docker.pkg.dev/${var.project_id}/${var.artifact_registry_repo}/spotify-history"
  ingest_job_image    = var.ingest_image_digest != "" ? "${local.job_image_base}@${var.ingest_image_digest}" : "${local.job_image_base}:${var.ingest_image_tag}"
  transform_job_image = var.transform_image_digest != "" ? "${local.job_image_base}@${var.transform_image_digest}" : "${local.job_image_base}:${var.transform_image_tag}"
  gcs_mount_path      = "/mnt/spotify-history"

  secret_ids = {
    spotify_token_json    = "projects/${var.project_id}/secrets/spotify-token-json"
    spotify_client_id     = "projects/${var.project_id}/secrets/spotify-client-id"
    spotify_client_secret = "projects/${var.project_id}/secrets/spotify-client-secret"
    spotify_redirect_uri  = "projects/${var.project_id}/secrets/spotify-redirect-uri"
  }

  secret_env = {
    SPOTIFY_TOKEN_JSON    = local.secret_ids.spotify_token_json
    SPOTIFY_CLIENT_ID     = local.secret_ids.spotify_client_id
    SPOTIFY_CLIENT_SECRET = local.secret_ids.spotify_client_secret
    SPOTIFY_REDIRECT_URI  = local.secret_ids.spotify_redirect_uri
  }

  job_plain_env = {
    GCP_PROJECT_ID = var.project_id
    GCS_BUCKET     = var.bucket_name
    GCS_MOUNT_PATH = local.gcs_mount_path
  }
}
