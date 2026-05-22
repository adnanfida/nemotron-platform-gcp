output "cluster_name" {
  value = module.cluster.cluster_name
}

output "cluster_endpoint" {
  value     = module.cluster.cluster_endpoint
  sensitive = true
}

output "weights_bucket_name" {
  value = module.data_plane.weights_bucket_name
}

output "gsa_email" {
  value       = module.iam.gsa_email
  description = "Use as the iam.gke.io/gcp-service-account annotation on the Helm chart's KSA"
}

output "memorystore_host" {
  value = module.data_plane.memorystore_host
}

output "artifact_registry_url" {
  value = module.data_plane.artifact_registry_url
}
