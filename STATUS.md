# Implementation Status

Running log of what's landed in the repo, with provenance and validation notes.

## 2026-05-22 — Phase 1 + Phase 2 scaffolding landed

PR: feat/phase1-phase2-scaffold → main (8 commits)

### What shipped

**Apps**
- `apps/inference/mock/` — CPU stub container (Python Flask, OpenAI-compatible `/v1/chat/completions`, Prometheus metrics on :9400). Verbatim from Spark's Implementation Catalog PDF.
- `apps/inference/helm/` — Helm chart with Chart.yaml, default values.yaml, 6 templates (Deployment, Service, HPA, PDB, ServiceAccount, PodMonitoring), and 5 profile values files:
  - `values-mock.yaml` — CPU stub
  - `values-dummy.yaml` — real vLLM container with `--load-format dummy --device cpu` (Gemini "Layer 1" dry-run pattern)
  - `values-l4.yaml` — 1× L4 + Nemotron Nano 8B NIM (functional testing)
  - `values-prod.yaml` — 2× H100 + 120B-NVFP4 NIM (the design doc target)
  - `values-l4-prod.yaml` — 4× L4 + 120B-NVFP4 NIM (cheaper alternative path from the Gemini deployment guide; throughput unverified)
- `apps/model-gateway/` — Cloud Run service skeleton. Hono + Node 22 + distroless final image. SSE proxy with session-affinity routing (stubbed), token-counter middleware (stubbed), timeout + error handling. Source verbatim from Spark with added timeout, error handling, and the two stub modules Spark imported but didn't include (`services/redis.ts`, `middleware/tokenCounter.ts`).

**Infra**
- `infra/terraform/modules/` — six modules with full HCL:
  - `networking` — VPC + subnet + Cloud NAT + Cloud Router
  - `iam` — `nemotron-gsa` GSA + Workload Identity binding + least-privilege roles
  - `cluster` — private GKE Standard + system pool + parameterized GPU pools
  - `data-plane` — GCS (CMEK) + Memorystore + Firestore + Artifact Registry + BigQuery + KMS
  - `observability` — Logging sink to BigQuery + Cloud Monitoring dashboard + queue-depth alert policy
  - `apigee` — disabled by default behind `var.enabled = false` (org provisioning takes ~30 min, hard to undo)
- `infra/terraform/envs/dev/` — composition calling all six modules with Mock-profile sizing (~$80/month). Includes apply recipe in `README.md`.

**CI**
- `.github/workflows/lint.yml` — four real lint jobs (terraform fmt + validate, helm lint + kubeconform, gateway tsc, mock py_compile). Replaces the conditional skip-everything jobs.

### Decisions made during implementation

1. **Spark's `values-prod.yaml` had bugs we fixed inline** rather than committing the broken version. Bugs: missing probes (pod would be killed before weights load), missing env vars (NIM auth would fail), missing imagePullSecret (ErrImagePull), missing serviceAccount (no Workload Identity), missing topology spread, empty HPA metric specification. Commit message on the helm chart commit documents the divergence from the PDF.
2. **Apigee module gated behind `var.enabled = false`** — provisioning takes ~30 min and orgs are not easily deletable. Operator opts in per environment.
3. **GPU node pools in cluster module** are a map (default empty) so each env declares its own. Dev env declares zero GPU pools.
4. **HPA on external metric is templated but commented "requires custom-metrics adapter"** — operator must install the adapter separately. Mock profile falls back to CPU-based HPA.
5. **Memorystore + Pub/Sub clients in the gateway are stubs.** Real implementations land in a follow-up PR after the Terraform data-plane apply confirms the connection details.
6. **Five profiles instead of three** — added `values-dummy.yaml` (Gemini Layer 1) and `values-l4-prod.yaml` (Gemini NVFP4-on-L4 path) on top of Spark's three (mock, l4, prod).

### Validated

| Check | Result |
|---|---|
| `helm lint apps/inference/helm` | clean |
| `helm template ... \| kubeconform -strict` for all 5 profiles | 5 valid + 1 skipped (PodMonitoring CRD) per profile |
| `terraform fmt -check -recursive` | clean |
| `terraform init -backend=false && terraform validate` for all 6 modules | clean |
| `terraform init -backend=false && terraform validate` for envs/dev | clean |
| `npx tsc --noEmit` in apps/model-gateway | clean |
| `python -m py_compile apps/inference/mock/app.py` | clean |

### What was NOT validated (and what the operator must verify post-merge)

- `terraform plan` against a real GCP project (no creds in this environment)
- `terraform apply` and the actual provisioning sequence
- Apigee module behavior when `enabled = true` (irreversible test)
- `helm install` against a live cluster
- vLLM container actually starting with `--load-format dummy --device cpu` (the structural YAML is right; runtime behavior unverified)
- 120B NIM image pull from nvcr.io (requires NVAIE entitlement on the NGC org)

### Known gaps surfaced for follow-up

- `apps/inference/mock/docker-compose.yaml` and `README.md` — Spark described these but didn't include them. Trivial to add when needed.
- Per-module deep READMEs — current READMEs are one-paragraph; expand if review surfaces specific questions.
- Real `getSessionReplicaHint` (ioredis client) in `apps/model-gateway/src/services/redis.ts`
- Real Pub/Sub publisher in `apps/model-gateway/src/middleware/tokenCounter.ts`
- Staging + prod env compositions
- Cloud Deploy progressive rollout pipeline (Phase 3 in NEXT_STEPS)
- Custom metrics adapter Helm install (external dependency for HPA-on-Prometheus to actually function)
- Smoke test against a real GCP sandbox project
