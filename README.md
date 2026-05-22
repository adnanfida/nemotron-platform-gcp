# nemotron-platform-gcp

> Production-grade infrastructure for NVIDIA Nemotron-3 on Google Cloud, designed for 2,000 concurrent active sessions.

**Status:** Scaffold / design phase. Not yet deployable. See [docs/architecture-2000-users.md](docs/architecture-2000-users.md) for the full design (12 pages with diagrams).

## What this is

Companion repo to [nemotron-on-gke](https://github.com/adnanfida/nemotron-on-gke) (the YAML-generator exploration tool). This repo holds the production-grade IaC for actually running Nemotron at scale on GCP.

The two repos serve different audiences:

| Repo | Audience | Purpose | Lifecycle |
|---|---|---|---|
| [nemotron-on-gke](https://github.com/adnanfida/nemotron-on-gke) | Devs, learners, sales engineering | Interactive YAML generator for exploration | One-shot, throwaway |
| **nemotron-platform-gcp** (this repo) | Platform / SRE | Versioned, multi-env production infrastructure | Long-lived, IaC-driven |

## Architecture summary

Six-layer architecture deployed in a single GCP region (us-central1, 3 zones):

1. **Edge / Security** — Cloud DNS, Cloud Armor (WAF + DDoS), Global HTTPS LB
2. **API Management** — Apigee X (per-tenant quotas, API keys, billing tags)
3. **Application Gateway** — Cloud Run (Model Gateway, session-affinity routing, SSE proxying, cost tracking)
4. **Inference Plane** — GKE Standard with 20–40 NIM pods (2× H100 each, NVLink-connected)
5. **State & Storage** — GCS, Memorystore, Firestore, BigQuery, Cloud KMS, Artifact Registry
6. **Observability** — Managed Prometheus, Cloud Monitoring, Logging, Trace

**Sized for:**
- ~200 RPS sustained, ~600 RPS peak
- p95 first-token latency < 2s, monthly availability > 99.9%
- ~$178K/month at production scale (90% GPU compute on 3-year CUD)

See [docs/architecture-2000-users.md](docs/architecture-2000-users.md) for the full design.

## Repo layout

```
nemotron-platform-gcp/
├── infra/
│   └── terraform/
│       ├── modules/
│       │   ├── cluster/          # GKE Standard + node pools + WI
│       │   ├── networking/       # VPC, subnets, NAT, PSC, VPC-SC
│       │   ├── apigee/           # Apigee org, proxies, products, quotas
│       │   ├── data-plane/       # GCS, Memorystore, Firestore, BigQuery, KMS
│       │   ├── observability/    # GMP, dashboards, alerts, SLOs
│       │   └── iam/              # GSAs, KSA bindings, role assignments
│       └── envs/
│           ├── dev/              # Mock profile — no GPU, CPU stub
│           ├── staging/          # Functional profile — 1× L4, Nano 8B
│           └── prod/             # Full design — 40× H100, 120B
├── apps/
│   ├── model-gateway/            # Cloud Run service for routing + observability
│   └── inference/
│       ├── mock/                 # CPU stub (returns canned OpenAI responses)
│       └── helm/                 # Helm chart for NIM Deployment + HPA + PDB
├── deploy/
│   └── cloud-deploy/             # Cloud Deploy pipeline + targets + custom strategies
├── docs/
│   ├── architecture-2000-users.md
│   └── img/                      # Architecture diagrams (drop nano-banana renders here)
└── .github/
    └── workflows/                # CI: tflint, terraform plan, helm lint, kubeconform
```

## Testing profiles (no H100 quota required to start)

The architecture supports five Helm values profiles, lightest to heaviest:

| Profile | GPU | Model | What it validates | Monthly cost |
|---|---|---|---|---|
| **Mock** (`values-mock.yaml`) | none | CPU Python stub | Manifests, gateway, routing, observability, HPA wiring | ~$80 |
| **Dummy** (`values-dummy.yaml`) | none | real vLLM container w/ `--load-format dummy --device cpu` | All of Mock + actual vLLM container startup args, probe wiring, API schema | ~$200 |
| **Functional** (`values-l4.yaml`) | 1× L4 | Llama-3.1-Nemotron Nano 8B NIM | All of Dummy + real inference path on a single GPU | ~$300–600 |
| **L4 Production** (`values-l4-prod.yaml`) | 4× L4 | Nemotron 120B-NVFP4 NIM | The full design at lower per-replica cost (~$5/hr vs $22/hr H100) — throughput unverified | depends on scale |
| **Production** (`values-prod.yaml`) | 2× H100 | Nemotron 120B-NVFP4 NIM | The full design doc target | ~$178K |

Each profile is a Helm `--values` overlay against the same chart. Switching profiles is a values file change, not a re-architecture.

## Current status

✅ **Phase 1 + Phase 2 scaffolded** — apps (mock, helm chart, gateway) and Terraform (six modules + dev env) all in place and lint-clean. See [STATUS.md](STATUS.md) for what landed and what's deferred.

🚧 **Not yet deployed** — `terraform apply` against a real GCP project hasn't been validated. The maintainer must verify post-merge.

See [NEXT_STEPS.md](NEXT_STEPS.md) for the work queue (Phase 1.5: wire up gateway stubs after first apply; Phase 3: CI/CD pipeline; Phase 4: operational artifacts).

## License

Apache-2.0
