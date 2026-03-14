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
  description = "Name of the Cloud Run job."
  type        = string
  default     = "spotify-history"
}

variable "cloud_run_image_tag" {
  description = "Image tag for the Cloud Run job container (for rollback/pinning)."
  type        = string
  default     = "latest"
}

variable "cloud_run_image_digest" {
  description = "Optional immutable image digest (sha256:...). If set, Cloud Run image uses @digest and ignores tag."
  type        = string
  default     = ""
}

variable "scheduler_region" {
  description = "Region for Cloud Scheduler jobs."
  type        = string
  default     = "us-central1"
}
