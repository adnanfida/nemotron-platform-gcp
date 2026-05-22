# apigee

API management plane. **Disabled by default.** Apigee org provisioning takes ~30 minutes, and orgs cannot be easily deleted (the `prevent_destroy` lifecycle flag is intentional). Opt in per environment by passing `enabled = true`.

## What this module creates (when enabled)

- `google_apigee_organization` — top-level Apigee X org (one per GCP project)
- `google_apigee_environment` — single environment (`nemotron-env`)
- `google_apigee_instance` — runtime instance in the configured region
- `google_apigee_instance_attachment` — binds the environment to the instance
- `google_apigee_envgroup` + attachment — optional, only if `envgroup_hostnames` is non-empty. Routes traffic for the named hostnames into the environment.

## What this module does NOT create

- API proxies, products, developers, apps — those are runtime config managed via the Apigee API/CI, not via Terraform.
- Quota policies — also runtime config.
- The cheaper alternative for ≤ ~10 tenants is **Cloud API Gateway** (managed Envoy). Consider before turning Apigee on.

## Cost note

- EVALUATION billing is free but rate-limited.
- PAYG is ~$0.50/hour for the smallest instance plus traffic charges.
- For dev environments, keep `enabled = false` and route traffic directly through the Cloud Run gateway.
