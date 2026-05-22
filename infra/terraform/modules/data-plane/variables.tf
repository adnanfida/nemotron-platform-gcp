variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "Region for Memorystore, Firestore, KMS keyring, Artifact Registry"
}

variable "name_prefix" {
  type        = string
  description = "Prefix for resource names"
  default     = "nemotron"
}

variable "weights_bucket_location" {
  type        = string
  description = "Location for the weights GCS bucket. Use a multi-region (US, EU) for prod; a single region for dev to save cost."
  default     = "US"
}

variable "weights_bucket_storage_class" {
  type        = string
  description = "Storage class for the weights bucket"
  default     = "STANDARD"
}

variable "memorystore_tier" {
  type        = string
  description = "Memorystore Redis tier (BASIC or STANDARD_HA)"
  default     = "BASIC"
}

variable "memorystore_memory_gb" {
  type        = number
  description = "Memorystore memory size in GB"
  default     = 1
}

variable "memorystore_network" {
  type        = string
  description = "VPC self-link the Memorystore instance peers with (from networking module)"
}

variable "firestore_location_id" {
  type        = string
  description = "Firestore database location (e.g. nam5, us-central1)"
  default     = "nam5"
}

variable "artifact_registry_repository_id" {
  type        = string
  description = "Artifact Registry repository ID for caching the NIM container"
  default     = "nemotron-cache"
}

variable "kms_protection_level" {
  type        = string
  description = "KMS protection level (SOFTWARE or HSM)"
  default     = "SOFTWARE"
}

variable "labels" {
  type        = map(string)
  description = "Resource labels"
  default     = {}
}
