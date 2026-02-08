output "bucket_name" {
  description = "Name of the created GCS bucket."
  value       = google_storage_bucket.this.name
}

output "bucket_url" {
  description = "gs:// URL of the bucket."
  value       = "gs://${google_storage_bucket.this.name}"
}
