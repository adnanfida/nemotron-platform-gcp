# Apps

Application code that runs inside the infrastructure.

## Layout

- **`model-gateway/`** — Cloud Run service. Handles SSE proxying, session-affinity routing via Memorystore, prompt shaping, token-count cost emission, and request cancellation propagation. The most consequential component beyond the inference workload itself.
- **`inference/helm/`** — Helm chart for the inference Deployment (NIM container), HPA, PDB, Service. Multi-environment values files swap between Mock / Functional / Production profiles.
- **`inference/mock/`** — CPU-only stub container that implements the OpenAI `/v1/chat/completions` API for testing the architecture without GPU quota. Returns canned responses with realistic delays; exposes the same Prometheus metrics as real NIM so the HPA wiring is validated end-to-end.

## Status

🚧 All directories are empty placeholders. Implementation queued in [`../NEXT_STEPS.md`](../NEXT_STEPS.md) Phase 1 (mock + helm chart + gateway).
