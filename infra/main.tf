data "google_project" "this" {
  project_id = var.project_id
}

resource "google_project_service" "cloudscheduler_api" {
  project = var.project_id
  service = "cloudscheduler.googleapis.com"
}

module "storage" {
  source = "./modules/storage"

  project_id  = var.project_id
  bucket_name = var.bucket_name
  location    = var.location
}

module "access" {
  source = "./modules/access"

  project_id             = var.project_id
  region                 = var.region
  artifact_registry_repo = var.artifact_registry_repo
  service_account_email  = local.job_service_account
  bucket_name            = module.storage.bucket_name
  secret_ids             = local.secret_ids
}

module "ingest_job" {
  source = "./modules/runtime_job"

  project_id                    = var.project_id
  region                        = var.region
  job_name                      = var.ingest_job_name
  image                         = local.ingest_job_image
  args                          = ["ingest"]
  service_account_email         = local.job_service_account
  bucket_name                   = module.storage.bucket_name
  mount_path                    = local.gcs_mount_path
  plain_env                     = local.job_plain_env
  secret_env                    = local.secret_env
  invoker_service_account_email = local.job_service_account
  project_number                = data.google_project.this.number
  scheduler_job_name            = "schedule-ingest-job"
  scheduler_description         = "Trigger ingestion Cloud Run job."
  scheduler_region              = var.scheduler_region
  scheduler_schedule            = var.ingest_schedule
  scheduler_retry_count         = 3

  depends_on = [
    google_project_service.cloudscheduler_api,
    module.access,
  ]
}

module "transform_job" {
  source = "./modules/runtime_job"

  project_id                    = var.project_id
  region                        = var.region
  job_name                      = var.transform_job_name
  image                         = local.transform_job_image
  args                          = ["transform"]
  service_account_email         = local.job_service_account
  bucket_name                   = module.storage.bucket_name
  mount_path                    = local.gcs_mount_path
  plain_env                     = local.job_plain_env
  secret_env                    = local.secret_env
  invoker_service_account_email = local.job_service_account
  project_number                = data.google_project.this.number
  scheduler_job_name            = "schedule-transform-job"
  scheduler_description         = "Trigger transform Cloud Run job."
  scheduler_region              = var.scheduler_region
  scheduler_schedule            = var.transform_schedule
  scheduler_time_zone           = var.transform_time_zone
  scheduler_retry_count         = 1
  scheduler_headers             = { "Content-Type" = "application/json" }

  depends_on = [
    google_project_service.cloudscheduler_api,
    module.access,
  ]
}

moved {
  from = google_storage_bucket.this
  to   = module.storage.google_storage_bucket.this
}

moved {
  from = google_cloud_run_v2_job.spotify_history_ingest
  to   = module.runtime.module.ingest_job.google_cloud_run_v2_job.this
}

moved {
  from = module.runtime.module.ingest_job.google_cloud_run_v2_job.this
  to   = module.ingest_job.google_cloud_run_v2_job.this
}

moved {
  from = google_cloud_run_v2_job.spotify_history_transform
  to   = module.runtime.module.transform_job.google_cloud_run_v2_job.this
}

moved {
  from = module.runtime.module.transform_job.google_cloud_run_v2_job.this
  to   = module.transform_job.google_cloud_run_v2_job.this
}

moved {
  from = google_cloud_scheduler_job.ingest
  to   = module.scheduler_ingest.google_cloud_scheduler_job.this
}

moved {
  from = module.scheduler_ingest.google_cloud_scheduler_job.this
  to   = module.ingest_job.google_cloud_scheduler_job.scheduler
}

moved {
  from = google_cloud_scheduler_job.transform
  to   = module.scheduler_transform.google_cloud_scheduler_job.this
}

moved {
  from = module.scheduler_transform.google_cloud_scheduler_job.this
  to   = module.transform_job.google_cloud_scheduler_job.scheduler
}

moved {
  from = google_secret_manager_secret_iam_member.spotify_token_json
  to   = module.access.google_secret_manager_secret_iam_member.secret_access["spotify_token_json"]
}

moved {
  from = google_secret_manager_secret_iam_member.spotify_client_id
  to   = module.access.google_secret_manager_secret_iam_member.secret_access["spotify_client_id"]
}

moved {
  from = google_secret_manager_secret_iam_member.spotify_client_secret
  to   = module.access.google_secret_manager_secret_iam_member.secret_access["spotify_client_secret"]
}

moved {
  from = google_secret_manager_secret_iam_member.spotify_redirect_uri
  to   = module.access.google_secret_manager_secret_iam_member.secret_access["spotify_redirect_uri"]
}

moved {
  from = google_storage_bucket_iam_member.job_writer
  to   = module.access.google_storage_bucket_iam_member.job_writer
}

moved {
  from = google_artifact_registry_repository_iam_member.job_puller
  to   = module.access.google_artifact_registry_repository_iam_member.job_puller
}

moved {
  from = google_cloud_run_v2_job_iam_binding.binding_ingest
  to   = module.access.google_cloud_run_v2_job_iam_binding.job_invoker["ingest"]
}

moved {
  from = module.access.google_cloud_run_v2_job_iam_binding.job_invoker["ingest"]
  to   = module.ingest_job.google_cloud_run_v2_job_iam_binding.job_invoker
}

moved {
  from = google_cloud_run_v2_job_iam_binding.binding_transform
  to   = module.access.google_cloud_run_v2_job_iam_binding.job_invoker["transform"]
}

moved {
  from = module.access.google_cloud_run_v2_job_iam_binding.job_invoker["transform"]
  to   = module.transform_job.google_cloud_run_v2_job_iam_binding.job_invoker
}
