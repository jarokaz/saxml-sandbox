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


output "node_pool_sa_email" {
  description = "The email of the node pool sa"
  value       = local.node_pool_sa_email
}

output "wid_sa_email" {
  description = "The email of the workload identity sa"
  value       = local.wid_sa_email
}

output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = module.cluster.name
}

output "cluster_endpoint" {
  description = "The endpoint for the GKE cluster"
  value       = module.cluster.endpoint
}

output "cluster_certificate" {
  sensitive = true
  value     = module.cluster.ca_certificate
}

# Mitigation for the lack of validations on multiple input variables
#output "validate_network_config" {
#  value = null
#
#  precondition {
#    condition = 1 == sum([for c in [
#    var.vpc_ref != null, var.vpc_config != null] : c ? 1 : 0])
#    error_message = "You must configure vpc_ref or vpc_config but not both."
#  }
#}


