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
  _tpl_providers = "${path.module}/templates/providers.tf.tpl"

  providers = {
    "env" = templatefile(local._tpl_providers, {
      backend_extra = join("\n", [
        "# remove the newline between quotes and set the prefix to the folder for Terraform state",
        "prefix = \"",
        "\""
      ])
      bucket = module.automation_gcs.name
      name   = "tf_automation"
      sa     = module.automation_sa.email
    })
  }
}

output "automation_gcs" {
  description = "GCS bucket where Terraform automation artifacts are managed"
  value       = module.automation_gcs.name
}

output "automation_sa" {
  description = "The email of the automation service account"
  value       = module.automation_sa.email
}

resource "google_storage_bucket_object" "providers" {
  for_each = local.providers
  bucket   = module.automation_gcs.name
  name     = "providers/${each.key}-providers.tf"
  content  = each.value
}
