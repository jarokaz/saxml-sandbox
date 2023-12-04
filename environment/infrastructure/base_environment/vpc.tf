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
  network_self_link      = try(var.vpc_ref.network_self_link, module.vpc.0.self_link)
  subnet_self_link       = try(var.vpc_ref.subnet_self_link, module.vpc.0.subnet_self_links["${var.vpc_config.subnet_region}/${var.vpc_config.subnet_name}"])
  pods_ip_range_name     = try(var.vpc_ref.pods_ip_range_name, var.vpc_config.secondary_ip_ranges.pods)
  services_ip_range_name = try(var.vpc_ref.services_ip_range_name, var.vpc_config.secondary_ip_ranges.services)
}

module "vpc" {
  source                   = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc?ref=v28.0.0&depth=1"
  count                    = var.vpc_config != null ? 1 : 0
  project_id               = var.project_id
  name                     = var.vpc_config.network_name
  routing_mode             = "REGIONAL"
  create_googleapis_routes = null
  subnets = [
    {
      name                = var.vpc_config.subnet_name
      ip_cidr_range       = var.vpc_config.ip_cidr_range
      region              = var.vpc_config.subnet_region
      secondary_ip_ranges = var.vpc_config.secondary_ip_ranges
    }
  ]
}
