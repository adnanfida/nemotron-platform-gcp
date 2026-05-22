resource "google_container_cluster" "this" {
  name     = var.cluster_name
  project  = var.project_id
  location = var.region

  network    = var.network
  subnetwork = var.subnet

  # Delete the default node pool; we manage system + GPU pools explicitly.
  remove_default_node_pool = true
  initial_node_count       = 1

  release_channel {
    channel = var.release_channel
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  dynamic "master_authorized_networks_config" {
    for_each = length(var.authorized_networks) > 0 ? [1] : []
    content {
      dynamic "cidr_blocks" {
        for_each = var.authorized_networks
        content {
          cidr_block   = cidr_blocks.value.cidr_block
          display_name = cidr_blocks.value.display_name
        }
      }
    }
  }

  addons_config {
    gcs_fuse_csi_driver_config {
      enabled = true
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  monitoring_config {
    managed_prometheus {
      enabled = true
    }
  }

  resource_labels = var.labels

  lifecycle {
    ignore_changes = [node_config]
  }
}

resource "google_container_node_pool" "system" {
  name     = "system-pool"
  project  = var.project_id
  location = var.region
  cluster  = google_container_cluster.this.name

  node_count = var.system_node_pool.node_count

  node_config {
    machine_type = var.system_node_pool.machine_type
    disk_size_gb = var.system_node_pool.disk_size_gb
    disk_type    = "pd-balanced"

    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    labels = merge(var.labels, {
      role = "system"
    })
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

resource "google_container_node_pool" "gpu" {
  for_each = var.gpu_node_pools

  name     = each.key
  project  = var.project_id
  location = var.region
  cluster  = google_container_cluster.this.name

  autoscaling {
    min_node_count = each.value.min_count
    max_node_count = each.value.max_count
  }

  node_config {
    machine_type = each.value.machine_type
    disk_size_gb = each.value.disk_size_gb
    disk_type    = "pd-ssd"
    spot         = each.value.spot

    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]

    guest_accelerator {
      type  = each.value.accelerator_type
      count = each.value.accelerator_count

      gpu_driver_installation_config {
        gpu_driver_version = "LATEST"
      }
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    dynamic "ephemeral_storage_local_ssd_config" {
      for_each = each.value.local_ssd_count > 0 ? [1] : []
      content {
        local_ssd_count = each.value.local_ssd_count
      }
    }

    labels = merge(var.labels, {
      role                             = "inference"
      "cloud.google.com/gke-node-pool" = each.key
    })

    taint {
      key    = "nvidia.com/gpu"
      value  = "present"
      effect = "NO_SCHEDULE"
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  lifecycle {
    ignore_changes = [node_count]
  }
}
