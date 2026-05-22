variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "gsa_name" {
  type        = string
  description = "Name (not email) of the Google Service Account used by Nemotron inference pods"
  default     = "nemotron-gsa"
}

variable "ksa_namespace" {
  type        = string
  description = "Kubernetes namespace containing the inference workload's KSA"
  default     = "default"
}

variable "ksa_name" {
  type        = string
  description = "Name of the Kubernetes ServiceAccount that the GSA will be bound to"
  default     = "nemotron-sa"
}

variable "weights_bucket_name" {
  type        = string
  description = "GCS bucket name for model weights (granted storage.objectUser to the GSA)"
}

variable "additional_roles" {
  type        = list(string)
  description = "Additional project-level roles to grant the GSA beyond the defaults"
  default     = []
}
