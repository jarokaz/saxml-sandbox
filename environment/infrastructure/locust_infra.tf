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


locals {
    default_message_schema = "syntax = \"proto3\";\n\nmessage Metrics {\n  string test_id=1;\n  string request_type = 2;\n  string request_name=3;\n  int32 response_length=4;\n  float response_time=5;\n  string start_time=6;\n  optional string model_name=7;\n  optional string model_method=8;\n  optional int32 num_output_tokens=9;\n  optional int32 num_input_tokens=10;\n  optional int32 model_server_response_time=11;\n  optional string prompt=12;\n  optional string prompt_parameters=13;\n  optional string completions=14;\n}"
    default_table_schema = <<EOF
[
    {
        "name": "subscription_name",
        "type": "STRING",
        "mode": "NULLABLE",
        "description": "Subscription name"

    }, 
    {
        "name": "message_id",
        "type": "STRING",
        "mode": "NULLABLE",
        "description": "Test ID"

    },
    {
        "name": "publish_time",
        "type": "TIMESTAMP",
        "mode": "NULLABLE",
        "description": "Test ID"

    },
    {
        "name": "attributes",
        "type": "JSON",
        "mode": "NULLABLE",
        "description": "Message attributes"

    },
    {
        "name": "data",
        "type": "JSON",
        "mode": "NULLABLE",
        "description": "Message data"

    },
    {
        "name": "test_id",
        "type": "STRING",
        "mode": "NULLABLE",
        "description": "Test ID"

    },
    {
        "name": "request_type",
        "type": "STRING",
        "mode": "NULLABLE",
        "description": "Request type"

    },
    {
        "name": "request_name",
        "type": "STRING",
        "mode": "NULLABLE",
        "description": "Request name"

    },
    {
        "name": "response_length",
        "type": "INT64",
        "mode": "NULLABLE",
        "description": "Response length"

    },   
    {
        "name": "response_time",
        "type": "FLOAT64",
        "mode": "NULLABLE",
        "description": "Response time in miliseconds"

    },     
    {
        "name": "start_time",
        "type": "DATETIME",
        "mode": "NULLABLE",
        "description": "Response time"

    },
    {
        "name": "model_name",
        "type": "STRING",
        "mode": "NULLABLE",
        "description": "Model name"

    },
    {
        "name": "model_method",
        "type": "STRING",
        "mode": "NULLABLE",
        "description": "Model name"
    },
    {
        "name": "num_output_tokens",
        "type": "INT64",
        "mode": "NULLABLE",
        "description": "Model name"
    },
    {
        "name": "num_input_tokens",
        "type": "INT64",
        "mode": "NULLABLE",
        "description": "Number of input tokens"
    },
    {
        "name": "model_server_response_time",
        "type": "INT64",
        "mode": "NULLABLE",
        "description": "Response time from a model server"
    },
    {
        "name": "prompt",
        "type": "STRING",
        "mode": "NULLABLE",
        "description": "LLM Prompt"
    },
    {
        "name": "prompt_parameters",
        "type": "JSON",
        "mode": "NULLABLE",
        "description": "Decoder parameters"
    },
    {
        "name": "completions",
        "type": "JSON",
        "mode": "NULLABLE",
        "description": "LLM completions"
    }
]
EOF
}

resource "google_pubsub_topic" "locust_sink" {
    name = var.locust_pubsub_sink
    depends_on = [google_pubsub_schema.locust_metrics_schema]

    schema_settings {
        schema="projects/${data.google_project.project.project_id}/schemas/locust_metrics_schema"
        encoding = "JSON"
    }

    labels = {
        test_environment = "saxml"
    }

    message_retention_duration = "86600s"
}

resource "google_pubsub_schema" "locust_metrics_schema" {
    name       = "locust_metrics_schema"
    type       = "PROTOCOL_BUFFER"
    definition = local.default_message_schema
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
    schema              = local.default_table_schema 
}


resource "google_pubsub_subscription" "locust_bq_subscription" {
    name     = var.locust_pubsub_bq_subscription
    topic    = google_pubsub_topic.locust_sink.name

    bigquery_config {
        table               = "${google_bigquery_table.locust_metrics.project}.${google_bigquery_table.locust_metrics.dataset_id}.${google_bigquery_table.locust_metrics.table_id}"  
        use_topic_schema    = true
        drop_unknown_fields = true 
        write_metadata      = true
    }

    depends_on = [google_project_iam_member.viewer, google_project_iam_member.editor]
}


resource "google_project_iam_member" "viewer" {
  project = data.google_project.project.project_id
  role    = "roles/bigquery.metadataViewer"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}


resource "google_project_iam_member" "editor" {
  project = data.google_project.project.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}