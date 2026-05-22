output "log_sink_writer_identity" {
  value       = google_logging_project_sink.gke_to_bq.writer_identity
  description = "Writer identity of the GKE-to-BigQuery logging sink"
}

output "dashboard_id" {
  value       = google_monitoring_dashboard.overview.id
  description = "ID of the overview Cloud Monitoring dashboard"
}
