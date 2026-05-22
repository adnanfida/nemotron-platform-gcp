variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region for the regional cluster"
}

variable "cluster_name" {
  type        = string
  description = "GKE cluster name"
  default     = "nemotron-cluster"
}

variable "network" {
  type        = string
  description = "VPC network self-link (from networking module)"
}

variable "subnet" {
  type        = string
  description = "Subnet self-link (from networking module)"
}

variable "pods_range_name" {
  type        = string
  description = "Secondary range name for pods"
  default     = "gke-pods"
}

variable "services_range_name" {
  type        = string
  description = "Secondary range name for services"
  default     = "gke-services"
}

variable "master_ipv4_cidr_block" {
  type        = string
  description = "CIDR block for the GKE control plane (must not overlap with VPC)"
  default     = "172.16.0.0/28"
}

variable "release_channel" {
  type        = string
  description = "GKE release channel (RAPID, REGULAR, STABLE)"
  default     = "REGULAR"
}

variable "system_node_pool" {
  type = object({
    machine_type = string
    node_count   = number
    disk_size_gb = optional(number, 100)
  })
  description = "System node pool sized for gateway proxies and daemonsets"
  default = {
    machine_type = "e2-standard-4"
    node_count   = 1
    disk_size_gb = 100
  }
}

variable "gpu_node_pools" {
  type = map(object({
    machine_type      = string
    accelerator_type  = string
    accelerator_count = number
    min_count         = number
    max_count         = number
    spot              = optional(bool, false)
    disk_size_gb      = optional(number, 200)
    local_ssd_count   = optional(number, 0)
  }))
  description = "Map of GPU node pool name -> config. Empty by default; populate per-env."
  default     = {}
}

variable "authorized_networks" {
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  description = "Authorized networks allowed to reach the GKE control plane"
  default     = []
}

variable "labels" {
  type        = map(string)
  description = "Resource labels"
  default     = {}
}
