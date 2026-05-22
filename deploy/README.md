# Deploy

CI/CD pipeline definitions for progressive rollout.

## Layout

- **`cloud-deploy/`** — Google Cloud Deploy pipeline + targets + custom deployment strategy.

## Rollout shape (per design doc)

1. **Canary**: 1 GKE replica with the new image, 5% traffic via gateway header
2. **Soak**: 10% traffic for 30 minutes, watching p95 latency against SLO
3. **Rollout**: 100% via rolling update, respecting PDB (`minAvailable: 18`)

Failed soak triggers automatic rollback. Manual approval required between canary and rollout in prod (auto in dev/staging).

Model weight releases use a separate pipeline with blue/green at the Service label level — two Deployments, switch selector when ready.

## Status

🚧 Empty placeholder. Queued in [`../NEXT_STEPS.md`](../NEXT_STEPS.md) Phase 3.
