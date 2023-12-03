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
  node_pool_sa_email = (
    var.create_service_accounts
    ? try(module.node_pool_service_account.0, null)
    : try(data.google_service_account.service_account.0, null)
  )
  
  create_node_pool_sa var.node_pool_sa

  project_roles = [for role in var.node_pools_sa_roles : "roles/${role}"]
}


module "node_pool_service_account" {
  source       = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account?ref=v28.0.0&depth=1"
  count        = var.create_service_accounts ? 1 : 0
  project_id   = var.project_id
  name         = var.node_pools_sa_name
  display_name = "GKE node pool service account."

  iam_project_roles = {
    "${var.project_id}" = local.project_roles
  }
}

data "google_service_account" "service_account" {
  count      = var.create_service_accounts ? 0 : 1
  project    = var.project_id
  account_id = var.node_pools_sa_name
}
