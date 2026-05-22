# data-plane

State and storage stack:
- **GCS bucket** for model weights, CMEK-encrypted, versioned, last-3-versions retention.
- **Cloud KMS** keyring + key (`weights-key`) with 90-day rotation.
- **Memorystore Redis** for session-affinity hints, per-tenant rate counters, idempotency keys. Default is Basic tier 1GB for dev; bump to `STANDARD_HA` with 5GB+ for prod.
- **Firestore (Native mode)** for durable conversation history.
- **Artifact Registry** Docker repo for caching the NIM container image intra-region.
- **BigQuery dataset** for telemetry sink (Logging sink itself lives in the observability module).

## Memorystore requires Private Service Access

`connect_mode = "PRIVATE_SERVICE_ACCESS"` requires PSA range allocation on the VPC. This module doesn't allocate it — assumes the operator has run `gcloud compute addresses create google-managed-services-... --purpose=VPC_PEERING ...` and `gcloud services vpc-peerings connect ...` once per project. Document this in the env README.

## CMEK on GCS

The GCS service agent (`service-PROJECT_NUMBER@gs-project-accounts.iam.gserviceaccount.com`) is granted `cryptoKeyEncrypterDecrypter` on the KMS key — without this, bucket creation fails with a permission error.
