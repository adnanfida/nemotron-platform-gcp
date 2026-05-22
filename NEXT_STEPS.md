# Next Steps

Roadmap for filling in the remaining work. Items grouped by phase, in priority order. See [STATUS.md](STATUS.md) for what's already landed.

## Phase 1 — Mock testing profile — DONE (PR feat/phase1-phase2-scaffold)

- [x] CPU-only stub inference container (`apps/inference/mock/`)
- [x] Helm chart for inference with five values profiles (mock, dummy, l4, prod, l4-prod)
- [x] Cloud Run model gateway skeleton (Hono + distroless), with `services/redis.ts` and `middleware/tokenCounter.ts` as stubs
- [x] CI: helm lint + kubeconform + tsc + py_compile
- [ ] Smoke test against minikube to confirm Mock profile works locally — **operator task post-merge**
- [ ] `apps/inference/mock/docker-compose.yaml` and `README.md` — trivial, deferred

## Phase 2 — Terraform infra modules — DONE for modules + dev env (same PR)

- [x] `modules/networking`, `iam`, `cluster`, `data-plane`, `observability`, `apigee`
- [x] `envs/dev` — Mock profile sized (~$80/month)
- [ ] `envs/staging` — Functional profile (1× L4 + Nano 8B) — next session
- [ ] `envs/prod` — full production sizing — pending the H100 vs 4× L4 decision (see Open Questions)
- [x] CI: terraform fmt -check + validate per module and env

## Phase 1.5 — Wire up the gateway's stubs (after dev env is applied)

These were left as deliberate stubs because they need real GCP infra to test against.

- [ ] Real Memorystore client in `apps/model-gateway/src/services/redis.ts` (ioredis, read MEMORYSTORE_HOST + MEMORYSTORE_PORT from env). Wire host into the Cloud Run service via `module.data_plane.memorystore_host`.
- [ ] Real Pub/Sub publisher in `apps/model-gateway/src/middleware/tokenCounter.ts`. Topic created in a follow-up data-plane module change.
- [ ] Add prompt shaping (max_tokens cap, safety filters) to the gateway.
- [ ] Add request cancellation propagation (close upstream fetch when client disconnects).

## Phase 2.5 — Custom metrics adapter

HPA on `vllm:num_requests_waiting` requires the `external.metrics.k8s.io` adapter. The Helm chart references the metric but the adapter is a separate install.

- [ ] Add `apps/custom-metrics-adapter/` with the GMP adapter Helm install or a Cloud Console runbook.
- [ ] Document the install step in the env READMEs.

## Phase 3 — CI/CD pipeline (deferred — needs operator decisions)

- [ ] Cloud Build trigger on push to main (builds Model Gateway image, pushes to Artifact Registry)
- [ ] Cloud Deploy pipeline definition with canary (5%) → soak (10%, 30 min) → rollout stages
- [ ] Model weight release pipeline (separate, manual gated, blue/green at Service label level)
- [ ] GitHub Actions to GCP via Workload Identity Federation (no long-lived PAT)

## Phase 4 — Operational artifacts (deferred — needs first real deploy first)

- [ ] Runbook (`docs/runbook.md`) — on-call procedures, common failures, debug recipes
- [ ] SLI/SLO definitions (`docs/slo.md`) — formal SLOs with error-budget policy
- [ ] Cost tracking BigQuery views + scheduled queries
- [ ] On-call alert routing (PagerDuty / Opsgenie integration)
- [ ] Real chart definitions in the observability dashboard (current is skeleton with 2 starter charts)

## Open Questions (need operator answer before Phase 2 envs/prod)

1. **Apigee X vs Cloud API Gateway** — decision hinges on tenant count and SLA differentiation. Apigee is ~$2K/mo even for low volume.
2. **3-year CUD commitment for prod GPUs** — acceptable, or plan for 1-year + spot mix?
3. **NVAIE entitlement on the NGC org** — confirm before any prod deploy. Without it, the 120B NIM container won't pull.
4. **L4 NVFP4 throughput claim** — the `values-l4-prod.yaml` profile assumes ~500 tok/s/replica from the Gemini doc, but that number is unverified. Find a third-party benchmark (Artificial Analysis, NVIDIA, vLLM community) before committing prod to the L4 path.
5. **Workload shape** — design doc assumes 2,000 concurrent active sessions (200 RPS sustained). Gemini doc assumes 2,000 DAU × 10% concurrency = ~67 parallel generations. These differ 10×. Confirm which is real.

## Decisions worth revisiting

- **Model gateway language**: TypeScript vs Go. TypeScript matches `nemotron-on-gke`; Go gives lower memory footprint on Cloud Run and is more idiomatic for proxying.
- **Helm vs Kustomize vs Config Connector**: chose Helm for templating multi-env values. Kustomize is more K8s-native but worse for environment-specific knob tuning. Config Connector eliminates Terraform for K8s-managed resources but adds operator complexity.
- **One repo vs split**: monorepo for ease of cross-cutting changes. Split repos make per-team ownership clearer but require coordination.
