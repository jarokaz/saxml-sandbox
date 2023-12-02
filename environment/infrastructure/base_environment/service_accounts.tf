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


#locals {
#  gke_service_account_email = var.gke_sa_email == "" ? module.service_account[0].email : var.gke_sa_email
#  project_roles             = [for role in var.gke_sa_roles : "${var.project_id}=>roles/${role}"]
#}


module "gke_service_account" {
  source                 = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account?ref=v28.0.0&depth=1"
  project_id             = data.google_project.project.project_id
  name                   = var.gke_sa_name
  service_account_create = var.gke_sa_create
  display_name           = "GKE node pool service account."
  # allow SA used by CI/CD workflow to impersonate this SA
  #iam = {
  #  "roles/iam.serviceAccountTokenCreator" = compact([
  #    try(module.automation-tf-cicd-sa["bootstrap"].iam_email, null)
  #  ])
  #}
  #iam_storage_roles = {
  #  (module.automation_gcs.name) = ["roles/storage.admin"]
  #}

  #iam_project_roles = {
  #  "${module.project_config.project_id}" = [
  #    # To Do. Restrict the roles
  #    "roles/editor"
  #  ]
  #}
}
