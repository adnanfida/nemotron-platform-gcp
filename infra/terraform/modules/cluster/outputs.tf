output "cluster_name" {
  value       = google_container_cluster.this.name
  description = "GKE cluster name"
}

output "cluster_endpoint" {
  value       = google_container_cluster.this.endpoint
  description = "GKE cluster control-plane endpoint"
  sensitive   = true
}

output "cluster_ca_certificate" {
  value       = google_container_cluster.this.master_auth[0].cluster_ca_certificate
  description = "Base64-encoded CA cert for the cluster"
  sensitive   = true
}

output "cluster_location" {
  value       = google_container_cluster.this.location
  description = "Cluster region/zone"
}

output "workload_pool" {
  value       = "${var.project_id}.svc.id.goog"
  description = "Workload Identity pool for binding KSAs to GSAs"
}
