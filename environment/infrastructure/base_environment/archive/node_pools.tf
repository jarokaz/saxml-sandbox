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
  tpu_types = {
    v5litepod-1   = ["1x1", 1, "tpu-v5-lite-podslice", "ct5lp-hightpu-1t", 1, true]
    v5litepod-4   = ["2x2", 1, "tpu-v5-lite-podslice", "ct5lp-hightpu-4t", 4, true]
    v5litepod-8   = ["2x4", 1, "tpu-v5-lite-podslice", "ct5lp-hightpu-8t", 8, true]
    v5litepod-16  = ["4x4", 4, "tpu-v5-lite-podslice", "ct5lp-hightpu-4t", 4, false]
    v5litepod-32  = ["4x8", 8, "tpu-v5-lite-podslice", "ct5lp-hightpu-4t", 4, false]
    v5litepod-64  = ["8x8", 16, "tpu-v5-lite-podslice", "ct5lp-hightpu-4t", 4, false]
    v5litepod-128 = ["8x16", 32, "tpu-v5-lite-podslice", "ct5lp-hightpu-4t", 4, false]
    v5litepod-256 = ["16x16", 64, "tpu-v5-lite-podslice", "ct5lp-hightpu-4t", 4, false]
    v4-8          = ["2x2x1", 1, "tpu-v4-podslice", "ct4p-hightpu-4t", 4, true]
    v4-16         = ["2x2x2", 2, "tpu-v4-podslice", "ct4p-hightpu-4t", 4, false]
    v4-32         = ["2x2x4", 4, "tpu-v4-podslice", "ct4p-hightpu-4t", 4, false]
    v4-64         = ["2x4x4", 8, "tpu-v4-podslice", "ct4p-hightpu-4t", 4, false]
    v4-128        = ["4x4x4", 16, "tpu-v4-podslice", "ct4p-hightpu-4t", 4, false]
    v4-256        = ["4x4x8", 32, "tpu-v4-podslice", "ct4p-hightpu-4t", 4, false]
    v4-512        = ["4x8x8", 64, "tpu-v4-podslice", "ct4p-hightpu-4t", 4, false]
    v4-1024       = ["8x8x8", 128, "tpu-v4-podslice", "ct4p-hightpu-4t", 4, false]
    v4-1536       = ["8x8x12", 192, "tpu-v4-podslice", "ct4p-hightpu-4t", 4, false]
    v4-2048       = ["8x8x16", 256, "tpu-v4-podslice", "ct4p-hightpu-4t", 4, false]
    v4-4096       = ["8x16x16", 512, "tpu-v4-podslice", "ct4p-hightpu-4t", 4, false]
  }

  cpu_nodel_pool = {
    name            = "cpu-node-pool"
    machine_type    = var.cpu_pool_machine_type
    node_locations  = var.zone
    autoscaling     = true
    min_count       = 1
    max_count       = var.cpu_pool_node_count
    local_ssd_count = 0
    spot            = false
    disk_size_gb    = var.cpu_pool_disk_size
    disk_type       = var.cpu_pool_disk_type
    image_type      = "COS_CONTAINERD"
    enable_gcfs     = false
    enable_gvnic    = false
    auto_repair     = true
    auto_upgrade    = true
    preemptible     = false
  }

  saxml_admin_node_pool = {
    name            = "saxml-admin-node-pool"
    machine_type    = var.saxml_admin_pool_machine_type
    node_locations  = var.zone
    autoscaling     = false
    node_count      = var.saxml_admin_pool_node_count
    local_ssd_count = 0
    spot            = false
    disk_size_gb    = var.cpu_pool_disk_size
    disk_type       = var.cpu_pool_disk_type
    image_type      = "COS_CONTAINERD"
    enable_gcfs     = false
    enable_gvnic    = false
    auto_repair     = true
    auto_upgrade    = true
    preemptible     = false
  }

  saxml_converter_nodel_pool = {
    name            = "saxml-converter-node-pool"
    machine_type    = var.saxml_converter_pool_machine_type
    node_locations  = var.zone
    autoscaling     = true
    min_count       = 0
    max_count       = var.saxml_converter_pool_node_count
    local_ssd_count = 0
    spot            = false
    disk_size_gb    = var.saxml_converter_pool_disk_size
    disk_type       = var.saxml_converter_pool_disk_type
    image_type      = "COS_CONTAINERD"
    enable_gcfs     = false
    enable_gvnic    = false
    auto_repair     = true
    auto_upgrade    = true
    preemptible     = false
  }

  tpu_autoscaling_config = {
    autoscaling          = true
    total_min_node_count = local.tpu_types[var.tpu_type][1] == 1 ? var.tpu_total_min_nodes : null
    total_max_node_count = local.tpu_types[var.tpu_type][1] == 1 ? var.tpu_total_max_nodes : null
    max_node_count       = local.tpu_types[var.tpu_type][1] == 1 ? null : local.tpu_types[var.tpu_type][1]
    location_policy      = "ANY"
  }

  #  tpu_node_pool_config = {
  #    machine_type       = local.tpu_types[var.tpu_type][3]
  #    node_locations     = var.zone
  #    initial_node_count = var.enable_tpu_autoscaling ? 0 : (local.tpu_types[var.tpu_type][1] == 1 ? var.tpu_num_nodes : local.tpu_types[var.tpu_type][1])
  #    autoscaling        = var.enable_tpu_autoscaling ? local.tpu_autoscaling_config : null
  #  }

  tpu_node_pool_config = {
    machine_type       = local.tpu_types[var.tpu_type][3]
    node_locations     = var.zone
    initial_node_count = var.enable_tpu_autoscaling ? 0 : (local.tpu_types[var.tpu_type][1] == 1 ? var.tpu_num_nodes : local.tpu_types[var.tpu_type][1])
    autoscaling        = var.enable_tpu_autoscaling
  }

  tpu_node_pool_names = [for index in range(var.num_tpu_pools) : { name = "${var.tpu_node_pool_name_prefix}-${index}" }]
  tpu_node_pools      = [for name_config in local.tpu_node_pool_names : merge(name_config, local.tpu_node_pool_config)]

  #node_pools = [
  #  local.cpu_nodel_pool,
  #  local.saxml_admin_node_pool,
  #  local.saxml_converter_nodel_pool
  #]
  node_pools = concat([
    local.cpu_nodel_pool,
    local.saxml_admin_node_pool,
    local.saxml_converter_nodel_pool],
  local.tpu_node_pools)

  node_pools_labels = {
    all = {}

    cpu-node-pool = {
      default-node-pool = true
    }

    saxml-admin-node-pool = {
      saxml-admin-node-pool = true
    }
  }

  node_pools_taints = {
    all = []

    saxml-admin-node-pool = [
      {
        key    = "saxml-admin-node-pool"
        value  = true
        effect = "NO_SCHEDULE"
      }
    ]
  }

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/cloud-platform",
    ]

  }
}
