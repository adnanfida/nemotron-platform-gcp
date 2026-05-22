locals {
  labels = {
    env         = "dev"
    cost_center = "nemotron-platform"
    owner       = "adnanfida"
  }
  name_prefix = "nemotron-dev"
}

module "networking" {
  source = "../../modules/networking"

  project_id  = var.project_id
  region      = var.region
  name_prefix = local.name_prefix
  labels      = local.labels
}

module "data_plane" {
  source = "../../modules/data-plane"

  project_id              = var.project_id
  region                  = var.region
  name_prefix             = local.name_prefix
  weights_bucket_location = var.region # single-region for dev (cheaper than multi-region)
  memorystore_tier        = "BASIC"
  memorystore_memory_gb   = 1
  memorystore_network     = module.networking.network_id
  firestore_location_id   = var.region
  labels                  = local.labels
}

module "iam" {
  source = "../../modules/iam"

  project_id          = var.project_id
  ksa_namespace       = "default"
  ksa_name            = "nemotron-sa"
  weights_bucket_name = module.data_plane.weights_bucket_name
}

# Mock profile: no GPU node pools. system-pool only — runs the CPU stub
# inference container from apps/inference/mock and the Cloud Run gateway's
# dev workload.
module "cluster" {
  source = "../../modules/cluster"

  project_id          = var.project_id
  region              = var.region
  cluster_name        = "${local.name_prefix}-cluster"
  network             = module.networking.network_id
  subnet              = module.networking.subnet_id
  pods_range_name     = module.networking.pods_range_name
  services_range_name = module.networking.services_range_name
  authorized_networks = var.authorized_networks
  labels              = local.labels

  system_node_pool = {
    machine_type = "e2-standard-4"
    node_count   = 1
    disk_size_gb = 50
  }

  gpu_node_pools = {} # mock profile — no GPU pools
}

module "observability" {
  source = "../../modules/observability"

  project_id           = var.project_id
  name_prefix          = local.name_prefix
  telemetry_dataset_id = module.data_plane.telemetry_dataset_id
  cluster_name         = module.cluster.cluster_name
  # No notification channels in dev — alerts are advisory only.
  alert_notification_channels = []
}

# Apigee disabled in dev. Set enabled = true here only if you specifically
# want to test API proxy policies; otherwise traffic goes directly through
# the Cloud Run gateway -> GKE Service path.
module "apigee" {
  source = "../../modules/apigee"

  enabled    = false
  project_id = var.project_id
  region     = var.region
}
