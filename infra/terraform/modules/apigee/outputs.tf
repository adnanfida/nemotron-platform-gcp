output "enabled" {
  value       = var.enabled
  description = "Whether the module actually provisioned Apigee resources"
}

output "org_id" {
  value       = var.enabled ? google_apigee_organization.this[0].id : null
  description = "Apigee organization ID (null when disabled)"
}

output "environment_name" {
  value       = var.enabled ? google_apigee_environment.this[0].name : null
  description = "Apigee environment name"
}

output "instance_host" {
  value       = var.enabled ? google_apigee_instance.this[0].host : null
  description = "Apigee instance internal host"
}
