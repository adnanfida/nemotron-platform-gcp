# iam

Creates the Google Service Account (`nemotron-gsa`) for the Nemotron inference workload, binds it to the in-cluster KSA (`default/nemotron-sa` by default) via Workload Identity, and grants least-privilege project + bucket roles.

## Roles granted

Project-level (always):
- `roles/secretmanager.secretAccessor` — read NGC API key, HF token from Secret Manager
- `roles/logging.logWriter`, `roles/monitoring.metricWriter`, `roles/monitoring.viewer`, `roles/cloudtrace.agent` — telemetry
- `roles/artifactregistry.reader` — pull cached NIM image from intra-region Artifact Registry

Bucket-level (always):
- `roles/storage.objectUser` on the weights bucket (passed via `weights_bucket_name`)

Additional roles can be appended via `additional_roles`.

## Consumer wiring

On the KSA side (Helm chart already handles this when `serviceAccount.workloadIdentity.enabled = true`):

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: nemotron-sa
  namespace: default
  annotations:
    iam.gke.io/gcp-service-account: <module.iam.gsa_email>
```
