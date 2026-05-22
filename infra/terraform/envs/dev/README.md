# envs/dev — Mock testing profile

Composes the six modules with sizing tuned for the **Mock profile**: no GPU node pools, single-zone subnet, Memorystore Basic 1GB, Apigee disabled. Target cost ~$80/month (mostly the GKE cluster control plane + system node).

## What this provisions

| Component | Sized as |
|---|---|
| VPC + subnet | regional in us-central1 |
| GKE cluster | 1× `e2-standard-4` system node, no GPU pools |
| GCS weights bucket | single-region, CMEK-encrypted |
| Memorystore Redis | Basic tier, 1 GB |
| Firestore | Native mode, us-central1 |
| Artifact Registry | DOCKER repo for NIM image cache |
| BigQuery | telemetry dataset |
| KMS keyring + weights key | 90-day rotation |
| Workload Identity binding | `default/nemotron-sa` (KSA) ↔ `nemotron-gsa` (GSA) |
| Cloud Monitoring dashboard | starter (queue depth + GPU util charts) |
| Apigee | **disabled** |

## How to use

1. Bootstrap a tfstate bucket (one time per project):

   ```bash
   gcloud storage buckets create gs://YOUR_PROJECT-tfstate \
     --project=YOUR_PROJECT --location=us-central1 --uniform-bucket-level-access
   gcloud storage buckets update gs://YOUR_PROJECT-tfstate --versioning
   ```

2. Uncomment + fill in the bucket name in `backend.tf`.

3. Copy `terraform.tfvars.example` to `terraform.tfvars` and set `project_id`.

4. (One time per project) Enable required APIs:

   ```bash
   gcloud services enable \
     container.googleapis.com compute.googleapis.com \
     iam.googleapis.com storage.googleapis.com \
     redis.googleapis.com firestore.googleapis.com \
     artifactregistry.googleapis.com cloudkms.googleapis.com \
     logging.googleapis.com monitoring.googleapis.com \
     bigquery.googleapis.com servicenetworking.googleapis.com \
     --project=YOUR_PROJECT
   ```

5. (One time per project) Allocate Private Service Access range for Memorystore:

   ```bash
   gcloud compute addresses create google-managed-services-default \
     --global --purpose=VPC_PEERING --prefix-length=16 \
     --network=default --project=YOUR_PROJECT
   gcloud services vpc-peerings connect \
     --service=servicenetworking.googleapis.com \
     --ranges=google-managed-services-default \
     --network=default --project=YOUR_PROJECT
   ```

6. Apply:

   ```bash
   terraform init
   terraform plan -out=tfplan
   terraform apply tfplan
   ```

7. Deploy the Mock inference workload via Helm against the new cluster:

   ```bash
   gcloud container clusters get-credentials nemotron-dev-cluster \
     --region=us-central1 --project=YOUR_PROJECT
   helm install nemotron-mock ../../../apps/inference/helm \
     -f ../../../apps/inference/helm/values-mock.yaml
   ```

## Important caveats

- **Cannot be `terraform apply`-ed from inside this repo's CI** — needs GCP creds. Run from a developer workstation or a Workload-Identity-Federation-authenticated CI runner.
- **First apply takes 15–20 minutes** mostly waiting for the GKE cluster + Firestore + Memorystore.
- **Destroy is gated** on the KMS key (the `prevent_destroy = false` in the data-plane module makes it possible but Firestore + Apigee don't allow destroy at all in some configs). Plan to abandon environments rather than tear them down if you've stored data.
