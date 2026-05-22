# All resources gated on var.enabled. When false this module is a no-op.

resource "google_apigee_organization" "this" {
  count = var.enabled ? 1 : 0

  project_id         = var.project_id
  analytics_region   = var.region
  runtime_type       = var.runtime_type
  billing_type       = var.billing_type
  authorized_network = var.network

  lifecycle {
    prevent_destroy = true # org deletion is largely irreversible
  }
}

resource "google_apigee_environment" "this" {
  count = var.enabled ? 1 : 0

  org_id = google_apigee_organization.this[0].id
  name   = "${var.name_prefix}-env"
}

resource "google_apigee_instance" "this" {
  count = var.enabled ? 1 : 0

  org_id   = google_apigee_organization.this[0].id
  name     = "${var.name_prefix}-instance"
  location = var.region
  # Instance sizing on Apigee X is fixed by the plan, not a configurable
  # disk size. Removed `disk_size_gb` after `terraform validate` rejected
  # it as not part of the resource schema.
}

resource "google_apigee_instance_attachment" "this" {
  count = var.enabled ? 1 : 0

  instance_id = google_apigee_instance.this[0].id
  environment = google_apigee_environment.this[0].name
}

resource "google_apigee_envgroup" "this" {
  count = var.enabled && length(var.envgroup_hostnames) > 0 ? 1 : 0

  org_id    = google_apigee_organization.this[0].id
  name      = "${var.name_prefix}-envgroup"
  hostnames = var.envgroup_hostnames
}

resource "google_apigee_envgroup_attachment" "this" {
  count = var.enabled && length(var.envgroup_hostnames) > 0 ? 1 : 0

  envgroup_id = google_apigee_envgroup.this[0].id
  environment = google_apigee_environment.this[0].name
}
