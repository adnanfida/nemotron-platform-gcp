variable "project_id" {
  type        = string
  description = "GCP project ID for the dev environment"
}

variable "region" {
  type        = string
  description = "Primary region"
  default     = "us-central1"
}

variable "authorized_networks" {
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  description = "CIDRs allowed to reach the GKE control plane (your office, VPN, etc.)"
  default     = []
}
