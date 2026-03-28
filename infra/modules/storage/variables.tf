variable "project_id" {
  description = "GCP project ID where resources will be created."
  type        = string
}

variable "bucket_name" {
  description = "Globally unique name for the GCS bucket."
  type        = string
}

variable "location" {
  description = "GCS bucket location (e.g. US, EU)."
  type        = string
}
