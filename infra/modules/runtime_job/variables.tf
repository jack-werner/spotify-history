variable "project_id" {
  description = "GCP project ID where the Cloud Run job is created."
  type        = string
}

variable "region" {
  description = "Region for the Cloud Run job."
  type        = string
}

variable "job_name" {
  description = "Cloud Run job name."
  type        = string
}

variable "image" {
  description = "Container image reference (tag or digest)."
  type        = string
}

variable "args" {
  description = "Arguments passed to the job container."
  type        = list(string)
}

variable "service_account_email" {
  description = "Service account used by the job."
  type        = string
}

variable "bucket_name" {
  description = "GCS bucket mounted into the job."
  type        = string
}

variable "mount_path" {
  description = "Mount path for the GCS volume."
  type        = string
}

variable "plain_env" {
  description = "Plain-text environment variables."
  type        = map(string)
  default     = {}
}

variable "secret_env" {
  description = "Secret-backed environment variables keyed by env var name."
  type        = map(string)
  default     = {}
}

variable "invoker_service_account_email" {
  description = "Service account used by scheduler to invoke this job."
  type        = string
}

variable "project_number" {
  description = "GCP project number used in the Cloud Run Jobs API URI."
  type        = string
}

variable "scheduler_job_name" {
  description = "Cloud Scheduler job name for this runtime job."
  type        = string
}

variable "scheduler_description" {
  description = "Cloud Scheduler job description."
  type        = string
}

variable "scheduler_region" {
  description = "Region for Cloud Scheduler."
  type        = string
}

variable "scheduler_schedule" {
  description = "Cron expression for Cloud Scheduler."
  type        = string
}

variable "scheduler_time_zone" {
  description = "Time zone for scheduler execution."
  type        = string
  default     = null
}

variable "scheduler_attempt_deadline" {
  description = "Attempt deadline for scheduler invocations."
  type        = string
  default     = "320s"
}

variable "scheduler_retry_count" {
  description = "Retry count for scheduler invocations."
  type        = number
}

variable "scheduler_headers" {
  description = "Optional HTTP headers for scheduler target request."
  type        = map(string)
  default     = {}
}
