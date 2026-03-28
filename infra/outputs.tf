output "bucket_name" {
  description = "Name of the created GCS bucket."
  value       = module.storage.bucket_name
}

output "bucket_url" {
  description = "gs:// URL of the bucket."
  value       = module.storage.bucket_url
}

output "ingest_job_name" {
  description = "Name of the ingestion Cloud Run job."
  value       = module.ingest_job.job_name
}

output "ingest_job_region" {
  description = "Region of the ingestion Cloud Run job."
  value       = module.ingest_job.job_region
}

output "transform_job_name" {
  description = "Name of the transform Cloud Run job."
  value       = module.transform_job.job_name
}

output "transform_job_region" {
  description = "Region of the transform Cloud Run job."
  value       = module.transform_job.job_region
}
