variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "name_prefix" {
  type        = string
  description = "Prefix for resource names"
  default     = "nemotron"
}

variable "telemetry_dataset_id" {
  type        = string
  description = "BigQuery dataset ID receiving GKE container logs (from data-plane module)"
}

variable "cluster_name" {
  type        = string
  description = "GKE cluster name (used as the Logging filter)"
}

variable "alert_notification_channels" {
  type        = list(string)
  description = "Notification channel IDs (e.g. PagerDuty, email) that alert policies fire to"
  default     = []
}
