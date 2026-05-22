variable "enabled" {
  type        = bool
  description = "Master switch. When false (default), this module is a no-op. Apigee org provisioning takes ~30 min and is hard to undo, so it must be explicitly opted into per environment."
  default     = false
}

variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "Region for the Apigee instance"
}

variable "name_prefix" {
  type        = string
  description = "Prefix for Apigee resource names"
  default     = "nemotron"
}

variable "network" {
  type        = string
  description = "VPC self-link for the Apigee instance to peer with"
  default     = null
}

variable "billing_type" {
  type        = string
  description = "Apigee org billing type (EVALUATION, PAYG, SUBSCRIPTION)"
  default     = "EVALUATION"
}

variable "runtime_type" {
  type        = string
  description = "Apigee runtime type (CLOUD or HYBRID)"
  default     = "CLOUD"
}

variable "envgroup_hostnames" {
  type        = list(string)
  description = "Hostnames served by the Apigee envgroup (e.g. [\"api.example.com\"])"
  default     = []
}
