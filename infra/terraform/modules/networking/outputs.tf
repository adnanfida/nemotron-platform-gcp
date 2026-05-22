output "network_id" {
  value       = google_compute_network.this.id
  description = "Self-link of the VPC network"
}

output "network_name" {
  value       = google_compute_network.this.name
  description = "Name of the VPC network"
}

output "subnet_id" {
  value       = google_compute_subnetwork.this.id
  description = "Self-link of the regional subnet"
}

output "subnet_name" {
  value       = google_compute_subnetwork.this.name
  description = "Name of the regional subnet"
}

output "pods_range_name" {
  value       = "gke-pods"
  description = "Name of the secondary range used for GKE pod IPs"
}

output "services_range_name" {
  value       = "gke-services"
  description = "Name of the secondary range used for GKE service IPs"
}
