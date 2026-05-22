# Terraform — Infrastructure

Provisions the GCP infrastructure for the production architecture. See [`../../docs/architecture-2000-users.md`](../../docs/architecture-2000-users.md) for what each module corresponds to.

## Layout

```
terraform/
├── modules/                       # Reusable modules, one per architectural concern
│   ├── networking/                # VPC, subnets, NAT, PSC, VPC-SC
│   ├── cluster/                   # GKE Standard + node pools + Workload Identity
│   ├── iam/                       # GSAs, KSA bindings, role assignments
│   ├── data-plane/                # GCS, Memorystore, Firestore, BigQuery, KMS, Artifact Registry
│   ├── observability/             # GMP, Cloud Monitoring dashboards, alerts, SLOs
│   └── apigee/                    # Apigee org, proxies, products, quotas
└── envs/
    ├── dev/                       # Mock profile — no GPU, CPU stub for the inference workload
    ├── staging/                   # Functional profile — 1× L4, Nemotron Nano 8B
    └── prod/                      # Production sizing — 40× H100, 120B NVFP4
```

## Status

🚧 All module directories are empty. Implementation is queued in [`../../NEXT_STEPS.md`](../../NEXT_STEPS.md) Phase 2.

## Conventions (when modules land)

- Each module: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `README.md`
- Provider versions pinned in `versions.tf` per module
- State backend: GCS bucket per environment, configured in `envs/<env>/backend.tf`
- Variables: passed from env-level configs; modules never read directly from `terraform.tfvars`
- All resources tagged with `env`, `cost-center`, `owner` labels for billing attribution
- Apigee module is the only one that may take 30+ minutes to apply (org provisioning); gated behind a separate workspace
