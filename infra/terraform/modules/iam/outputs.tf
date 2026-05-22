output "gsa_email" {
  value       = google_service_account.this.email
  description = "Email of the Google Service Account (use this for the KSA's iam.gke.io/gcp-service-account annotation)"
}

output "gsa_id" {
  value       = google_service_account.this.id
  description = "Fully-qualified ID of the Google Service Account"
}
