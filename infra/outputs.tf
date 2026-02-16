output "bucket_name" {
  description = "Name of the created GCS bucket."
  value       = google_storage_bucket.this.name
}

output "bucket_url" {
  description = "gs:// URL of the bucket."
  value       = "gs://${google_storage_bucket.this.name}"
}

output "cloud_run_job_name" {
  description = "Name of the Cloud Run job (for gcloud run jobs execute ...)."
  value       = google_cloud_run_v2_job.spotify_history.name
}

output "cloud_run_job_region" {
  description = "Region of the Cloud Run job."
  value       = google_cloud_run_v2_job.spotify_history.location
}
