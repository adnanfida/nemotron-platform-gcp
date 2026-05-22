# Next Steps

Roadmap for filling in the scaffolding. Items grouped by phase, in priority order.

## Phase 1 — Mock testing profile (highest priority for first iteration)

**Goal:** validate the full architecture end-to-end without GPU quota or cost. Catches every architectural bug except the inference-specific ones.

- [ ] Write CPU-only stub inference container (`apps/inference/mock/`)
  - Speaks OpenAI `/v1/chat/completions` API
  - Returns canned/templated responses with realistic decode delays
  - Exposes `vllm:num_requests_waiting` Prometheus metric (so HPA wiring works)
  - Exposes `/v1/health/ready` and `/v1/health/live`
  - Python Flask is fine; ~100 LoC
- [ ] Write Helm chart for inference (`apps/inference/helm/`) with profile values
  - `values-mock.yaml` (CPU stub, no GPU request)
  - `values-l4.yaml` (1× L4, Nano 8B NIM)
  - `values-prod.yaml` (2× H100, 120B NIM)
- [ ] Write Cloud Run model gateway skeleton (`apps/model-gateway/`)
  - TypeScript (matches `nemotron-on-gke` language choice)
  - Implements: SSE proxy, Memorystore session lookup, prompt shaping, cost emit
- [ ] Write CI: `helm lint`, `kubeconform` against the rendered chart
- [ ] Smoke test against minikube to confirm Mock profile works locally

## Phase 2 — Terraform infra modules

- [ ] `modules/networking` — VPC, subnets in 3 zones, Cloud NAT, PSC endpoints for Memorystore/Firestore/Secret Manager, VPC-SC perimeter around weights bucket + Secret Manager
- [ ] `modules/cluster` — GKE Standard regional, private, Workload Identity on, node pools (system + gpu-on-demand + gpu-spot)
- [ ] `modules/iam` — Service accounts (nemotron-gsa), Workload Identity binding (KSA → GSA), role assignments
- [ ] `modules/data-plane` — GCS bucket (multi-region, CMEK), Memorystore Redis Standard, Firestore database, BigQuery dataset, KMS keyring + keys, Artifact Registry repository
- [ ] `modules/observability` — Managed Prometheus, custom-metrics adapter, dashboards (Cloud Monitoring), alert policies, SLOs
- [ ] `modules/apigee` — Apigee org provisioning, API proxies, products, per-tenant quotas
- [ ] `envs/dev` — calls modules with dev-sized parameters (no Apigee, single zone, minimal sizing)
- [ ] `envs/staging` — staging sized (1 GPU replica, smaller Memorystore)
- [ ] `envs/prod` — full production sizing per design doc
- [ ] CI: `terraform fmt -check`, `tflint`, `terraform validate` per module

## Phase 3 — CI/CD pipeline

- [ ] Cloud Build trigger on push to main (builds Model Gateway image)
- [ ] Cloud Deploy pipeline definition with canary (5%) → soak (10%, 30 min) → rollout stages
- [ ] Model weight release pipeline (separate, manual gated, blue/green at Service label level)
- [ ] GitHub Actions integration (Workload Identity Federation, no PAT)

## Phase 4 — Operational artifacts

- [ ] Runbook (`docs/runbook.md`) — on-call procedures, common failures, debug recipes
- [ ] SLI/SLO definitions (`docs/slo.md`) — formal SLOs with error-budget policy
- [ ] Cost tracking BigQuery views + scheduled queries (`docs/cost-analytics.md`)
- [ ] On-call alert routing (PagerDuty / Opsgenie integration)

## Open Questions (from design doc)

1. **Apigee X vs Cloud API Gateway** — decision hinges on tenant count and SLA differentiation. Apigee is ~$2K/mo even for low volume.
2. **3-year CUD commitment** — acceptable, or plan for 1-year + spot mix?
3. **NVAIE entitlement on NGC org** — required for the 120B NIM container. Confirm before Phase 2.
4. **Spend caps for dev/staging environments** — Mock profile (~$80/mo) is cheap; Functional with 1× L4 left running costs ~$500/mo if not scaled to zero.

## Decisions worth revisiting

- **Model gateway language**: TypeScript vs Go. TypeScript matches `nemotron-on-gke`; Go gives lower memory footprint on Cloud Run and is more idiomatic for proxying.
- **Helm vs Kustomize vs Config Connector**: chose Helm for templating multi-env values. Kustomize is more K8s-native but worse for environment-specific knob tuning. Config Connector eliminates Terraform for K8s-managed resources but adds operator complexity.
- **One repo vs split (infra-only + app-only)**: chose monorepo for ease of cross-cutting changes. Split repos make per-team ownership clearer but require coordination.
