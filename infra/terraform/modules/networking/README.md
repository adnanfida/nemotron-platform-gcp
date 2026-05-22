# networking

Provisions the VPC, regional subnet (with secondary ranges for GKE pods and services), Cloud Router, and Cloud NAT for outbound egress from private GKE nodes. NAT is required because the cluster module creates a private cluster (nodes have no public IPs); without it pods cannot pull container images from `nvcr.io` etc. on cold start.

## Notes
- `subnet_cidr` / `pods_cidr` / `services_cidr` should not overlap with any peered VPC.
- VPC Service Controls perimeter is **not** in this module — it's project-level and lives outside the GKE-specific stack.
