output "bucket_name" {
  description = "Name of the created GCS bucket."
  value       = google_storage_bucket.this.name
}

output "bucket_url" {
  description = "gs:// URL of the bucket."
  value       = "gs://${google_storage_bucket.this.name}"
}

output "ingest_job_name" {
  description = "Name of the ingestion Cloud Run job."
  value       = google_cloud_run_v2_job.spotify_history_ingest.name
}

output "ingest_job_region" {
  description = "Region of the ingestion Cloud Run job."
  value       = google_cloud_run_v2_job.spotify_history_ingest.location
}

output "transform_job_name" {
  description = "Name of the transform Cloud Run job."
  value       = google_cloud_run_v2_job.spotify_history_transform.name
}

output "transform_job_region" {
  description = "Region of the transform Cloud Run job."
  value       = google_cloud_run_v2_job.spotify_history_transform.location
}
