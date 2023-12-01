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

#resource "google_compute_network" "cluster_network" {
#  name                    = var.network_name
#  auto_create_subnetworks = "false"
#  routing_mode            = "REGIONAL"
#}
#
#resource "google_compute_subnetwork" "cluster_subnetwork" {
#  name                     = var.subnet_name
#  region                   = var.region
#  network                  = google_compute_network.cluster_network.self_link
#  ip_cidr_range            = var.subnet_ip_range
#  private_ip_google_access = true
#
#  secondary_ip_range {
#      range_name    = "ip-range-services"
#      ip_cidr_range = var.services_ip_range
#  }
#
#  secondary_ip_range {
#    range_name    = "ip-range-pods"
#    ip_cidr_range = var.pods_ip_range
#  }
#}

locals {
    network_name           = var.network_project_id == "" ?  element(split("/", module.vpc[0].network_self_link), length(split("/", module.vpc[0].network_self_link))-1) : var.network_name 
    subnet_name            = var.network_project_id == "" ?  element(split("/", module.vpc[0].subnets_self_links[0]), length(split("/", module.vpc[0].subnets_self_links[0]))-1) : var.subnet_name
    pods_ip_range_name     = var.pods_ip_range_name
    services_ip_range_name = var.services_ip_range_name
}

module "vpc" {
    count = var.network_project_id == "" ? 1 : 0 

    source  = "terraform-google-modules/network/google"
    version = "~> 8.0"

    project_id   = var.project_id 
    network_name = var.network_name 
    routing_mode = var.vpc_routing_mode 

    subnets = [
        {
            subnet_name           = var.subnet_name 
            subnet_ip             = var.subnet_ip_range 
            subnet_region         = var.region 
        },
    ]

    secondary_ranges = {
        "${var.subnet_name}" = [
            {
                range_name    = var.services_ip_range_name 
                ip_cidr_range = var.services_ip_range
            },
            {
                range_name    = var.services_ip_range_name 
                ip_cidr_range = var.pods_ip_range
            }
        ]
    }

}