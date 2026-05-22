# cluster

Regional, private GKE Standard cluster with Workload Identity enabled, GCS-FUSE CSI driver pre-installed, and Managed Prometheus on. A `system-pool` is always provisioned; GPU node pools are declared via the `gpu_node_pools` map (default empty, set per-env).

## Example GPU pool config (per-env)

```hcl
gpu_node_pools = {
  "gpu-pool" = {
    machine_type      = "a3-highgpu-2g"
    accelerator_type  = "nvidia-h100-80gb"
    accelerator_count = 2
    min_count         = 0    # min=0 means no GPUs billed until a pod requests them
    max_count         = 40
    local_ssd_count   = 16
  }
  "gpu-pool-spot" = {
    machine_type      = "a3-highgpu-2g"
    accelerator_type  = "nvidia-h100-80gb"
    accelerator_count = 2
    min_count         = 0
    max_count         = 20
    spot              = true
    local_ssd_count   = 16
  }
}
```

## Notes
- `private_cluster_config` enables private nodes (no public IPs). Make sure the Cloud NAT from the networking module is in place or pods will fail to pull images.
- All node pools use `WORKLOAD_METADATA` mode so Workload Identity works.
- GPU pools include the `nvidia.com/gpu=present:NoSchedule` taint so only pods with the matching toleration land there. The Helm chart's `tolerations` block in `values-prod.yaml` etc. provides this.
- `ignore_changes = [node_count]` on the GPU pools defers replica count to the cluster autoscaler — Terraform won't fight HPA scale events.
- The GCS-FUSE CSI driver is enabled at the cluster level via `addons_config`; Autopilot enables this by default but Standard requires the opt-in.
