# Remote state backend. Commented out so `terraform init -backend=false` works
# in CI. Uncomment + fill in the bucket name before running `terraform init`
# against a real GCP project.
#
# Prereq: the bucket must exist and the operator must have storage.objectAdmin
# on it. Recommended bootstrap:
#
#   gcloud storage buckets create gs://YOUR_PROJECT-tfstate \
#     --project=YOUR_PROJECT --location=us-central1 --uniform-bucket-level-access
#   gcloud storage buckets update gs://YOUR_PROJECT-tfstate --versioning
#
# terraform {
#   backend "gcs" {
#     bucket = "YOUR_PROJECT-tfstate"
#     prefix = "nemotron-platform/dev"
#   }
# }
