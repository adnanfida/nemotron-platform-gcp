output "weights_bucket_name" {
  value       = google_storage_bucket.weights.name
  description = "GCS bucket holding model weights"
}

output "weights_bucket_url" {
  value       = google_storage_bucket.weights.url
  description = "gs:// URL of the weights bucket"
}

output "kms_key_id" {
  value       = google_kms_crypto_key.weights.id
  description = "CMEK key protecting the weights bucket"
}

output "memorystore_host" {
  value       = google_redis_instance.sessions.host
  description = "Memorystore Redis host (private IP)"
}

output "memorystore_port" {
  value       = google_redis_instance.sessions.port
  description = "Memorystore Redis port"
}

output "artifact_registry_url" {
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.nim_cache.repository_id}"
  description = "Pullable URL prefix for the cached NIM image"
}

output "telemetry_dataset_id" {
  value       = google_bigquery_dataset.telemetry.dataset_id
  description = "BigQuery dataset receiving request logs + token usage"
}

output "firestore_name" {
  value       = google_firestore_database.this.name
  description = "Firestore database name"
}
