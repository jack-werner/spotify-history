variable "project_id" {
  description = "GCP project ID where IAM bindings are created."
  type        = string
}

variable "region" {
  description = "Region of the Artifact Registry repository."
  type        = string
}

variable "artifact_registry_repo" {
  description = "Artifact Registry repository ID containing app images."
  type        = string
}

variable "service_account_email" {
  description = "Service account receiving access."
  type        = string
}

variable "bucket_name" {
  description = "GCS bucket name for objectAdmin grant."
  type        = string
}

variable "secret_ids" {
  description = "Map of secret aliases to fully qualified Secret Manager IDs."
  type        = map(string)
}
