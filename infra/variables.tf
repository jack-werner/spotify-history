variable "project_id" {
  description = "GCP project ID where the bucket will be created."
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
