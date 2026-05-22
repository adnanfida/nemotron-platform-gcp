variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region for regional resources (subnet, router, NAT)"
}

variable "name_prefix" {
  type        = string
  description = "Prefix for all networking resource names"
  default     = "nemotron"
}

variable "subnet_cidr" {
  type        = string
  description = "Primary CIDR for the GKE subnet (nodes)"
  default     = "10.10.0.0/20"
}

variable "pods_cidr" {
  type        = string
  description = "Secondary range CIDR for GKE pods"
  default     = "10.100.0.0/16"
}

variable "services_cidr" {
  type        = string
  description = "Secondary range CIDR for GKE services"
  default     = "10.101.0.0/20"
}

variable "nat_min_ports_per_vm" {
  type        = number
  description = "Cloud NAT min ports per VM (raise for high-egress workloads like NIM image pulls)"
  default     = 64
}

variable "labels" {
  type        = map(string)
  description = "Labels applied to supported resources"
  default     = {}
}
