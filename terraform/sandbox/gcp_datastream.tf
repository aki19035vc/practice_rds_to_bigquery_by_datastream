resource "google_datastream_connection_profile" "database" {
  display_name          = "${local.app}-${local.env}-database"
  connection_profile_id = "${local.app}-${local.env}-database"
  location              = "asia-northeast1"

  mysql_profile {
    hostname = aws_db_instance.main.address
    username = "root"
    password = random_password.database_root_user.result
  }
}

resource "google_datastream_connection_profile" "bigquery" {
  display_name          = "${local.app}-${local.env}-bigquery"
  connection_profile_id = "${local.app}-${local.env}-bigquery"
  location              = "asia-northeast1"

  bigquery_profile {
  }
}

resource "google_datastream_stream" "main" {
  display_name = "${local.app}-${local.env}-database-to-bigquery"
  stream_id    = "${local.app}-${local.env}-database-to-bigquery"
  location     = "asia-northeast1"

  source_config {
    source_connection_profile = google_datastream_connection_profile.database.id

    mysql_source_config {
      max_concurrent_backfill_tasks = 0
      max_concurrent_cdc_tasks      = 0

      include_objects {
        mysql_databases {
          database = "orion"
        }
      }
    }
  }

  destination_config {
    destination_connection_profile = google_datastream_connection_profile.bigquery.id

    bigquery_destination_config {
      data_freshness = "0s" # 用途に応じて変更

      single_target_dataset {
        dataset_id = google_bigquery_dataset.database.id
      }
    }
  }

  backfill_all {
  }
}
