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
  gke_service_account_email = var.gke_sa_email == "" ? module.service_account[0].email : var.gke_sa_email
  project_roles = [for role in var.gke_sa_roles : "${var.project_id}=>roles/${role}"] 
}

module "service_account" {
  count         = var.gke_sa_email == "" ? 1 : 0
  source        = "terraform-google-modules/service-accounts/google"
  project_id    = var.project_id
  names         = [var.gke_sa_name]
  display_name  = "GKE service account"
  description   = "Service account for GKE node pools"
  project_roles = local.project_roles 
}