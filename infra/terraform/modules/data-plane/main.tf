data "google_project" "this" {
  project_id = var.project_id
}

# KMS keyring + key for CMEK.
resource "google_kms_key_ring" "this" {
  project  = var.project_id
  name     = "${var.name_prefix}-keyring"
  location = var.region
}

resource "google_kms_crypto_key" "weights" {
  name            = "${var.name_prefix}-weights-key"
  key_ring        = google_kms_key_ring.this.id
  rotation_period = "7776000s" # 90 days

  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = var.kms_protection_level
  }

  lifecycle {
    prevent_destroy = false # set true in prod
  }
}

# Grant the GCS service agent permission to use the CMEK key.
resource "google_kms_crypto_key_iam_member" "gcs_encrypter" {
  crypto_key_id = google_kms_crypto_key.weights.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.this.number}@gs-project-accounts.iam.gserviceaccount.com"
}

# GCS bucket for model weights.
resource "google_storage_bucket" "weights" {
  project       = var.project_id
  name          = "${var.project_id}-${var.name_prefix}-weights"
  location      = var.weights_bucket_location
  storage_class = var.weights_bucket_storage_class

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.weights.id
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 3
    }
    action {
      type = "Delete"
    }
  }

  labels = var.labels

  depends_on = [google_kms_crypto_key_iam_member.gcs_encrypter]
}

# Memorystore Redis for session affinity hints + rate counters + idempotency keys.
resource "google_redis_instance" "sessions" {
  project        = var.project_id
  name           = "${var.name_prefix}-sessions"
  tier           = var.memorystore_tier
  memory_size_gb = var.memorystore_memory_gb
  region         = var.region

  authorized_network = var.memorystore_network
  connect_mode       = "PRIVATE_SERVICE_ACCESS"

  redis_version = "REDIS_7_2"

  labels = var.labels
}

# Firestore for durable conversation history.
resource "google_firestore_database" "this" {
  project     = var.project_id
  name        = "(default)"
  location_id = var.firestore_location_id
  type        = "FIRESTORE_NATIVE"
}

# Artifact Registry — intra-region cache of the NIM container image.
resource "google_artifact_registry_repository" "nim_cache" {
  project       = var.project_id
  location      = var.region
  repository_id = var.artifact_registry_repository_id
  description   = "Intra-region cache of the NIM container image to avoid cold-start pull from nvcr.io"
  format        = "DOCKER"
  labels        = var.labels
}

# BigQuery dataset for request logs and cost analytics (observability module
# attaches the Logging sink; this just declares the dataset).
resource "google_bigquery_dataset" "telemetry" {
  project                    = var.project_id
  dataset_id                 = "${replace(var.name_prefix, "-", "_")}_telemetry"
  location                   = var.region
  description                = "Request logs (Apigee), token-usage events (Cloud Run gateway), GKE pod logs"
  delete_contents_on_destroy = false

  labels = var.labels
}
