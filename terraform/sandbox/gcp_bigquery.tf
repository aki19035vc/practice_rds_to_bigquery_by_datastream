resource "google_bigquery_dataset" "database" {
  dataset_id                 = "${local.app}_${local.env}_db"
  location                   = "asia-northeast1"
  max_time_travel_hours      = 48
  storage_billing_model      = "LOGICAL"
  delete_contents_on_destroy = true
}
