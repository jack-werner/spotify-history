resource "google_cloud_run_v2_job" "this" {
  name     = var.job_name
  location = var.region
  project  = var.project_id

  template {
    template {
      max_retries     = 0
      service_account = var.service_account_email

      volumes {
        name = "gcs-bucket"
        gcs {
          bucket = var.bucket_name
        }
      }

      containers {
        image = var.image
        args  = var.args

        volume_mounts {
          name       = "gcs-bucket"
          mount_path = var.mount_path
        }

        dynamic "env" {
          for_each = var.plain_env
          content {
            name  = env.key
            value = env.value
          }
        }

        dynamic "env" {
          for_each = var.secret_env
          content {
            name = env.key
            value_source {
              secret_key_ref {
                secret  = env.value
                version = "latest"
              }
            }
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [launch_stage]
  }
}

resource "google_cloud_run_v2_job_iam_binding" "job_invoker" {
  project  = var.project_id
  location = google_cloud_run_v2_job.this.location
  name     = google_cloud_run_v2_job.this.name
  role     = "roles/run.invoker"
  members  = ["serviceAccount:${var.invoker_service_account_email}"]
}

resource "google_cloud_scheduler_job" "scheduler" {
  name             = var.scheduler_job_name
  description      = var.scheduler_description
  schedule         = var.scheduler_schedule
  time_zone        = var.scheduler_time_zone
  attempt_deadline = var.scheduler_attempt_deadline
  region           = var.scheduler_region
  project          = var.project_id

  retry_config {
    retry_count = var.scheduler_retry_count
  }

  http_target {
    http_method = "POST"
    uri         = "https://${google_cloud_run_v2_job.this.location}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.project_number}/jobs/${google_cloud_run_v2_job.this.name}:run"
    headers     = var.scheduler_headers

    oauth_token {
      service_account_email = var.invoker_service_account_email
    }
  }

  depends_on = [google_cloud_run_v2_job_iam_binding.job_invoker]
}
