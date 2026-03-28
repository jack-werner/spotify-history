output "job_name" {
  description = "Cloud Run job name."
  value       = google_cloud_run_v2_job.this.name
}

output "job_region" {
  description = "Cloud Run job region."
  value       = google_cloud_run_v2_job.this.location
}

output "scheduler_job_name" {
  description = "Cloud Scheduler job name for this runtime job."
  value       = google_cloud_scheduler_job.scheduler.name
}
