# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

resource "google_pubsub_topic" "locust_sink" {
    name = var.locust_pubsub_sink

    labels = {
        test_environment = "saxml"
    }

    message_retention_duration = "86600s"
}


resource "google_bigquery_dataset" "locust_dataset" {
    dataset_id           = var.locust_bq_dataset_id
    friendly_name        = "Locust metrics"
    description          = "Locust metrics"
    location             = var.locust_bq_dataset_location

    access {
        role           = "OWNER"
        user_by_email  = module.workload_identity.gcp_service_account_email 
    }

}

resource "google_bigquery_table" "locust_metrics" {
    dataset_id          = google_bigquery_dataset.locust_dataset.dataset_id
    table_id            = var.locust_bq_table
    deletion_protection = false
    schema = <<EOF
[
    {
        "name": "json_metrics",
        "type": "JSON",
        "mode": "NULLABLE",
        "description": "JSON metrics blob"

    }
]
EOF
}


resource "google_pubsub_subscription" "locust_bq_subscription" {
    name     = var.locust_pubsub_bq_subscription
    topic    = google_pubsub_topic.locust_sink.name

    bigquery_config {
        table = "${google_bigquery_table.locust_metrics.project}.${google_bigquery_table.locust_metrics.dataset_id}.{google_bigquery_table.locust_metrics.table_id}"   
    }

    depends_on = [google_project_iam_member.viewer, google_project_iam_member.editor]
}


resource "google_project_iam_member" "viewer" {
  project = data.google_project.project.project_id
  role   = "roles/bigquery.metadataViewer"
  member = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}


resource "google_project_iam_member" "editor" {
  project = data.google_project.project.project_id
  role   = "roles/bigquery.dataEditor"
  member = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}