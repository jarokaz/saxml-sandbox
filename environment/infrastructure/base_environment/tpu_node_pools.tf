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

  single_host_tpu_node_pools = { for node_pool_name, node_pool in var.single_host_tpu_node_pools :
    node_pool_name => merge(
      {
      },
    )
  }

  multi_host_tpu_node_pools = { for node_pool_name, node_pool in var.multi_host_tpu_node_pools :
    node_pool_name => merge(
      {
      },
    )
  }
}


resource "google_container_node_pool" "single_host_tpu_node_pool" {
  for_each = local.single_host_tpu_node_pools

  provider           = google-beta
  project            = var.project_id
  cluster            = module.cluster.id
  name               = each.key
  node_locations     = each.value.zones
  initial_node_count = each.value.initial_node_count

  dynamic "autoscaling" {
    for_each = (
      try(each.value.autoscaling, null) != null
    ? [""] : [])
    content {
      total_min_node_count = each.value.total_min_node_count
      total_max_node_count = each.value.total_max_node_count
      location_policy      = "ANY"
    }
  }

  node_config {
    machine_type    = each.value.machine_type
    service_account = local.node_pool_sa_email
    oauth_scopes    = each.value.oauth_scopes
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
}

resource "google_container_node_pool" "multi_host_tpu_node_pool" {
  for_each = local.multi_host_tpu_node_pools

  provider           = google-beta
  project            = var.project_id
  cluster            = module.cluster.id
  name               = each.key
  node_locations     = each.value.zones
  initial_node_count = each.value.initial_node_count

  dynamic "autoscaling" {
    for_each = (
      try(each.value.autoscaling, null) != null
    ? [""] : [])
    content {
      max_node_count  = each.value.total_min_node_count
      location_policy = "ANY"
    }
  }

  node_config {
    machine_type    = each.value.machine_type
    service_account = local.node_pool_sa_email
    oauth_scopes    = each.value.oauth_scopes
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  placement_policy {
    type         = "COMPACT"
    tpu_topology = each.value.tpu_topology
  }
}
