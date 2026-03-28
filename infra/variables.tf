variable "project_id" {
  description = "GCP project ID where resources will be created."
  type        = string
}

variable "bucket_name" {
  description = "Globally unique name for the GCS bucket (e.g. spotify-history-<project_id>)."
  type        = string
}

variable "location" {
  description = "GCS bucket location (e.g. US, EU)."
  type        = string
  default     = "US"
}

variable "region" {
  description = "Region for the Cloud Run job and Artifact Registry image (e.g. us-central1)."
  type        = string
}

variable "artifact_registry_repo" {
  description = "Name of the Artifact Registry repository containing the spotify-history image."
  type        = string
}

variable "cloud_run_job_name" {
  description = "Deprecated single-job name (unused)."
  type        = string
  default     = "spotify-history"
}

variable "ingest_job_name" {
  description = "Name of the ingestion Cloud Run job."
  type        = string
  default     = "spotify-history-ingest"
}

variable "transform_job_name" {
  description = "Name of the transform Cloud Run job."
  type        = string
  default     = "spotify-history-transform"
}

variable "ingest_image_tag" {
  description = "Image tag for ingestion container (used when digest is empty)."
  type        = string
  default     = "latest"
}

variable "ingest_image_digest" {
  description = "Optional immutable digest for ingestion image (sha256:...)."
  type        = string
  default     = ""
}

variable "transform_image_tag" {
  description = "Image tag for transform container (used when digest is empty)."
  type        = string
  default     = "latest"
}

variable "transform_image_digest" {
  description = "Optional immutable digest for transform image (sha256:...)."
  type        = string
  default     = ""
}

variable "scheduler_region" {
  description = "Region for Cloud Scheduler jobs."
  type        = string
  default     = "us-central1"
}

variable "ingest_schedule" {
  description = "Cron schedule for ingestion Cloud Scheduler job."
  type        = string
  default     = "*/15 * * * *"
}

variable "transform_schedule" {
  description = "Cron schedule for transform Cloud Scheduler job."
  type        = string
  default     = "0 3 * * *"
}

variable "transform_time_zone" {
  description = "Time zone for transform schedule."
  type        = string
  default     = "America/New_York"
}
