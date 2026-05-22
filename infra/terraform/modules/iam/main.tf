locals {
  default_roles = [
    "roles/secretmanager.secretAccessor",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/cloudtrace.agent",
    "roles/artifactregistry.reader",
  ]
  all_roles = toset(concat(local.default_roles, var.additional_roles))
}

resource "google_service_account" "this" {
  project      = var.project_id
  account_id   = var.gsa_name
  display_name = "Nemotron inference workload identity"
  description  = "Bound to KSA ${var.ksa_namespace}/${var.ksa_name} via Workload Identity. Holds least-privilege roles for the inference plane."
}

# Workload Identity: KSA -> GSA binding.
resource "google_service_account_iam_binding" "workload_identity" {
  service_account_id = google_service_account.this.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[${var.ksa_namespace}/${var.ksa_name}]",
  ]
}

# Project-level roles.
resource "google_project_iam_member" "project_roles" {
  for_each = local.all_roles
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.this.email}"
}

# Bucket-level role on the weights bucket (scoped, not project-wide).
resource "google_storage_bucket_iam_member" "weights_reader" {
  bucket = var.weights_bucket_name
  role   = "roles/storage.objectUser"
  member = "serviceAccount:${google_service_account.this.email}"
}
