# observability

- **Logging sink** routes GKE container logs to the BigQuery `telemetry` dataset (from the data-plane module) with partitioned tables.
- **Cloud Monitoring dashboard** with two starter charts (queue depth, GPU utilization) sourced from Managed Prometheus.
- **Alert policy** (gated on `alert_notification_channels` being non-empty) firing when average queue depth exceeds 8 for 2 minutes — should precede HPA scale events by ~30s and surface scaling adapter issues.

## What's not here (intentionally)

- Notification channels themselves — these are project-wide and not env-scoped, so they live in a separate workspace.
- SLOs — `google_monitoring_slo` defs will land in a follow-up PR once we have a stable baseline for first-token latency.
- Per-tenant cost views — those are BigQuery saved queries against the telemetry dataset, separately managed.
