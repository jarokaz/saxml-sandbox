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


variable "project_id" {
  description = "The GCP project ID"
  type        = string
  nullable    = false
}

variable "region" {
  description = "The region for the environment"
  type        = string
  nullable    = false
}

variable "deletion_protection" {
  description = "Prevent Terraform from destroying data storage resources (storage buckets, GKE clusters). When this field is set, a terraform destroy or terraform apply that would delete data storage resources will fail."
  type        = bool
  default     = true
  nullable    = false
}

variable "prefix" {
  description = "Prefix used for resource names."
  type        = string
  default     = ""
  nullable    = false
}

variable "node_pool_sa" {
  description = "The config for a node pool service account. If email is set the existing service account is used. If name is a new account is created. If roles are null the default roles are used."
  type = object({
    name  = optional(string, "gke-node-pool-sa")
    email = optional(string, "")
    roles = optional(list(string), [
      "storage.objectAdmin",
      "logging.logWriter",
    ])
    description = optional(string, "GKE workload identity service account")
  })
  default = {
  }
  validation {
    condition     = !(var.node_pool_sa.email == "" && var.node_pool_sa.name == "")
    error_message = "Either email or name must be set."
  }
  nullable = false
}

variable "wid_sa" {
  description = "The config for a workload identity service account. If email is set the existing service account is used. If name is a new account is created. If roles are null the default roles are used."
  type = object({
    name  = optional(string, "gke-wid-sa")
    email = optional(string, "")
    roles = optional(list(string), [
      "storage.objectAdmin",
      "logging.logWriter",
    ])
    description = optional(string, "GKE node pool service account")
  })
  default = {
  }
  validation {
    condition     = !(var.wid_sa.email == "" && var.wid_sa.name == "")
    error_message = "Either email or name must be set."
  }
  nullable = false
}

variable "vpc_ref" {
  description = "Network configurations of an existing VPC to use for the environment. If null a new VPC based on the provided network_config will be created"
  type = object({
    host_project           = string
    network_self_link      = string
    subnet_self_link       = string
    pods_ip_range_name     = string
    services_ip_range_name = string
  })
  default = null
}

variable "vpc_config" {
  description = "Network configurations of a VPC to create. Must be specified if vpc_reg is null"
  type = object({
    network_name           = optional(string, "gke-cluster-network")
    subnet_name            = optional(string, "gke-cluster-subnetwork")
    subnet_ip_cidr_range   = optional(string, "10.129.0.0/20")
    pods_ip_cidr_range     = optional(string, "192.168.64.0/20")
    services_ip_cidr_range = optional(string, "192.168.80.0/20")
    routing_mode           = optional(string, "REGIONAL")
    nat_router_name        = optional(string, "nat-router")
  })
  default  = {}
  nullable = false
}


variable "cluster_config" {
  description = "Base cluster configurations"
  type = object({
    name                        = optional(string, "gke-ml-cluster")
    release_channel             = optional(string, "REGULAR")
    description                 = optional(string, "GKE ML inference cluster")
    gcs_fuse_csi_driver         = optional(bool, true)
    workload_identity           = optional(bool, true)
    workload_identity_namespace = optional(string, "serving-workloads")
    enable_workload_logs        = optional(bool, true)
  })
  default  = {}
  nullable = false
}

variable "cpu_node_pools" {
  description = "Configurations for CPU node pools"
  type = map(object({
    zones          = list(string)
    min_node_count = number
    max_node_count = number
    machine_type   = string
    disk_type      = optional(string, "pd-standard")
    disk_size_gb   = optional(string, 200)
    auto_repair    = optional(bool, true)
    auto_upgrade   = optional(bool, true)
    oauth_scopes   = optional(list(string), ["https://www.googleapis.com/auth/cloud-platform"])
    taints = optional(map(object({
      value  = string
      effect = string
    })))
  }))
  validation {
    condition = alltrue([
      for k, v in merge([for name, node_pool in var.cpu_node_pools : node_pool.taints]...) :
      contains(["NO_SCHEDULE", "PREFER_NO_SCHEDULE", "NO_EXECUTE"], v.effect)
    ])
    error_message = "Invalid taint effect."
  }
  default  = {}
  nullable = false
}

variable "tpu_node_pools" {
  description = "Configurations for TPU node pools"
  type = map(object({
    zones          = list(string)
    min_node_count = number
    max_node_count = number
    tpu_type       = string
    disk_type      = optional(string, "pd-standard")
    disk_size_gb   = optional(string, 200)
    gvnic          = optional(bool, true)
    #    auto_repair    = optional(bool, true)
    #    auto_upgrade   = optional(bool, true)
    oauth_scopes = optional(list(string), ["https://www.googleapis.com/auth/cloud-platform"])
    taints = optional(map(object({
      value  = string
      effect = string
    })))
  }))
  validation {
    condition = alltrue([
      for k, v in merge([for name, node_pool in var.tpu_node_pools : node_pool.taints]...) :
      contains(["NO_SCHEDULE", "PREFER_NO_SCHEDULE", "NO_EXECUTE"], v.effect)
    ])
    error_message = "Invalid taint effect."
  }
  default  = {}
  nullable = false
}

########################################
#
#variable "network_project_id" {
#  description = "The project ID of the VPC"
#  type        = string
#  default     = ""
#}
#
#variable "region" {
#  description = "The region for the environment resources"
#  type        = string
#}
#
#variable "zone" {
#  description = "The zone for a Vertex Notebook instance"
#  type        = string
#}
#
#
#variable "repository_bucket_name" {
#  description = "The GCS bucket name to be used as model repository"
#  type        = string
#}
#
#variable "saxml_admin_bucket_name" {
#  description = "The GCS bucket name to be used as Saxml admin bucket"
#  type        = string
#}
#
#
#
#variable "cluster_name" {
#  description = "The name of the GKE cluster"
#  type        = string
#}
#
#variable "cluster_description" {
#  description = "The cluster's description"
#  default     = "GKE cluster to host Saxml cell"
#}
#
#
#variable "cpu_pool_node_count" {
#  description = "The number of nodes in the default node pool"
#  default     = 3
#}
#
#variable "cpu_pool_machine_type" {
#  description = "The machine type for the CPU node pool"
#  default     = "n1-standard-8"
#}
#
#variable "cpu_pool_disk_size" {
#  description = "Disk size for nodes in CPU node pool"
#  default     = 200
#}
#
#variable "cpu_pool_disk_type" {
#  description = "Disk typ on for nodes in CPU node pool"
#  default     = "pd-standard"
#}
#
#variable "saxml_admin_pool_node_count" {
#  description = "The number of nodes in the Saxml admin node pool"
#  default     = 3
#}
#
#variable "saxml_admin_pool_machine_type" {
#  description = "The machine type for the Saxml admin node pool"
#  default     = "n1-standard-8"
#}
#
#variable "saxml_admin_pool_disk_size" {
#  description = "Disk size for nodes in the Saxml admin node pool"
#  default     = 200
#}
#
#variable "saxml_admin_pool_disk_type" {
#  description = "Disk typ on for nodes in the Saxml admin node pool"
#  default     = "pd-standard"
#}
#
#variable "saxml_converter_pool_node_count" {
#  description = "The number of nodes in the Saxml converter node pool"
#  default     = 3
#}
#
#variable "saxml_converter_pool_machine_type" {
#  description = "The machine type for the Saxml converter node pool"
#  default     = "n2-highmem-32"
#}
#
#variable "saxml_converter_pool_disk_size" {
#  description = "Disk size for nodes in the Saxml converter node pool"
#  default     = 200
#}
#
#variable "saxml_converter_pool_disk_type" {
#  description = "Disk typ on for nodes in the Saxml converter node pool"
#  default     = "pd-standard"
#}
#
#variable "saxml_sa_name" {
#  description = "The service account name for Saxml workload identity."
#  default     = "saxml-sa"
#}
#
#variable "saxml_sa_roles" {
#  description = "The roles to assign to the Saxml service account"
#  default = [
#    "roles/storage.objectAdmin",
#    "roles/storage.admin",
#    "roles/logging.logWriter",
#    "roles/pubsub.admin"
#  ]
#}
#

#
#variable "saxml_namespace" {
#  description = "The K8s namespace for the Saxml deployment."
#  default     = "saxml"
#}
#
#####  Networking
#variable "network_name" {
#  description = "The network name"
#  type        = string
#}
#
#variable "vpc_routing_mode" {
#  description = "The network routing mode"
#  default     = "REGIONAL"
#}
#
#variable "subnet_name" {
#  description = "The subnet name"
#  type        = string
#}
#
#variable "subnet_ip_range" {
#  description = "The IP address range for the subnet"
#  default     = "10.129.0.0/20"
#}
#
#variable "pods_ip_range" {
#  description = "The secondary IP range for pods"
#  type        = string
#  default     = "192.168.64.0/20"
#}
#
#variable "pods_ip_range_name" {
#  description = "The name  of the secondary IP range for pods"
#  type        = string
#}
#
#variable "services_ip_range" {
#  description = "The secondary IP range for services"
#  default     = "192.168.80.0/20"
#}
#
#variable "services_ip_range_name" {
#  description = "The name of the secondary IP range for services"
#  type        = string
#}
#
#variable "max_pods_per_node" {
#  description = "The maximum number of pods to schedule per node"
#  default     = 110
#}
#
#
#
#variable "gke_release_channel" {
#  description = "GKE release channel"
#  default     = "RAPID"
#}
#
#variable "gke_version" {
#  description = "GKE version"
#  default     = "latest"
#}
#
#variable "asm_release_channel" {
#  description = "GKE release channel"
#  default     = "regular"
#}
#
#variable "tpu_machine_type" {
#  description = "TPU machine type"
#  default     = "ct4p-hightpu-4t"
#}
#
#variable "tpu_type" {
#  description = "TPU type"
#  default     = "v4-8"
#}
#
#variable "tpu_node_pool_name_prefix" {
#  description = "TPU node pools name prefix"
#  default     = "tpu-node-pool"
#}
#
#variable "num_tpu_pools" {
#  description = "Number of TPU node pools."
#  default     = 1
#}
#
#variable "enable_tpu_autoscaling" {
#  description = "Enable TPU autoscaling"
#  default     = false
#}
#
#variable "tpu_total_min_nodes" {
#  description = "Total min nodes for autoscaling single-host TPU node pool"
#  type        = number
#  default     = 1
#}
#
#variable "tpu_total_max_nodes" {
#  description = "Total max nodes for autoscaling single-host TPU node pool"
#  type        = number
#  default     = 1
#}
#
#variable "tpu_num_nodes" {
#  description = "Num of nodes in non autoscaling single-host TPU node pool"
#  type        = number
#  default     = 1
#}
#
#variable "cluster_deletion_protection" {
#  description = "Whether or not to allow Terraform to destroy the cluster."
#  default     = false
#}
#
#variable "locust_pubsub_sink" {
#  description = "The name of the PubSub topic for Locust integration."
#  default     = "locust_pubsub_sink"
#}
#
#variable "locust_pubsub_bq_subscription" {
#  description = "The name of the PubSub BQ subscription for Locust integration."
#  default     = "locust_pubsub_bq_sub"
#}
#
#variable "locust_bq_dataset_id" {
#  description = "The name of the BigQuery dataset to manage Locust metrics"
#  default     = "locust_metrics_dataset"
#}
#
#variable "locust_bq_dataset_location" {
#  description = "The location of the BigQuery dataset to manage Locust metrics"
#  default     = "US"
#}
#
#variable "locust_bq_table" {
#  description = "The name of the BQ table to manage Locust metrics"
#  default     = "locust_metrics"
#}
#
#variable "message_schema" {
#  description = "PubSub message schema for locust"
#  default     = ""
#}
#
#variable "table_schema" {
#  description = "BigQuery table schema for locust"
#  default     = ""
#}
#
