data "google_project" "this" {
  project_id = var.project_id
}

# Route GKE container logs into BigQuery for analytics.
resource "google_logging_project_sink" "gke_to_bq" {
  project                = var.project_id
  name                   = "${var.name_prefix}-gke-to-bq"
  destination            = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${var.telemetry_dataset_id}"
  filter                 = "resource.type=\"k8s_container\" AND resource.labels.cluster_name=\"${var.cluster_name}\""
  unique_writer_identity = true

  bigquery_options {
    use_partitioned_tables = true
  }
}

# Grant the sink's writer identity permission to write to BigQuery.
resource "google_project_iam_member" "sink_writer" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = google_logging_project_sink.gke_to_bq.writer_identity
}

# Skeleton dashboard. Real chart definitions land in a follow-up PR.
resource "google_monitoring_dashboard" "overview" {
  project = var.project_id
  dashboard_json = jsonencode({
    displayName = "${var.name_prefix} — overview"
    mosaicLayout = {
      columns = 12
      tiles = [
        {
          width  = 6
          height = 4
          widget = {
            title = "Pod queue depth (vllm:num_requests_waiting)"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  prometheusQuery = "avg by (pod) (vllm_num_requests_waiting{cluster=\"${var.cluster_name}\"})"
                }
              }]
            }
          }
        },
        {
          width  = 6
          height = 4
          xPos   = 6
          widget = {
            title = "GPU utilization (DCGM_FI_DEV_GPU_UTIL)"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  prometheusQuery = "avg by (pod) (DCGM_FI_DEV_GPU_UTIL{cluster=\"${var.cluster_name}\"})"
                }
              }]
            }
          }
        }
      ]
    }
  })
}

# Alert: queue depth saturation (precedes HPA scale event by ~30s).
resource "google_monitoring_alert_policy" "queue_depth_high" {
  count = length(var.alert_notification_channels) > 0 ? 1 : 0

  project      = var.project_id
  display_name = "${var.name_prefix} — queue depth saturation"
  combiner     = "OR"

  conditions {
    display_name = "Average queue depth > 8 for 2 minutes"
    condition_prometheus_query_language {
      query    = "avg(vllm_num_requests_waiting{cluster=\"${var.cluster_name}\"})"
      duration = "120s"
    }
  }

  notification_channels = var.alert_notification_channels

  documentation {
    content   = "Queue depth across replicas is high. HPA should scale, but if it doesn't within 5 minutes investigate the custom-metrics adapter (external.metrics.k8s.io) and the Managed Prometheus scrape config."
    mime_type = "text/markdown"
  }
}
