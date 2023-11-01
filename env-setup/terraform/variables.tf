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
}

variable "region" {
    description = "The region for the environment resources"
    type        = string
}

variable "zone" {
    description = "The zone for a Vertex Notebook instance"
    type        = string
}


variable "repository_bucket_name" {
    description = "The GCS bucket name to be used as model repository"
    type        = string
}

variable "saxml_admin_bucket_name" {
    description = "The GCS bucket name to be used as Saxml admin bucket"
    type        = string
}

variable "force_destroy" {
    description = "Force destroy flag for the GCS buckets"
    default = true 
}

variable "cluster_name" {
    description = "The name of the GKE cluster"
    type        = string
}

variable "cluster_description" {
    description = "The cluster's description"
    default = "GKE cluster to host Saxml cell"
}


variable "cpu_pool_node_count" {
    description = "The number of nodes in the default node pool"
    default     = 3
}

variable "cpu_pool_machine_type" {
    description = "The machine type for the CPU node pool"
    default = "n1-standard-8"
}

variable "cpu_pool_disk_size" {
    description = "Disk size for nodes in CPU node pool"
    default = 200
}

variable "cpu_pool_disk_type" {
    description = "Disk typ on for nodes in CPU node pool"
    default = "pd-standard"
}

variable "saxml_admin_pool_node_count" {
    description = "The number of nodes in the Saxml admin node pool"
    default     = 3
}

variable "saxml_admin_pool_machine_type" {
    description = "The machine type for the Saxml admin node pool"
    default = "n1-standard-8"
}

variable "saxml_admin_pool_disk_size" {
    description = "Disk size for nodes in the Saxml admin node pool"
    default = 200
}

variable "saxml_admin_pool_disk_type" {
    description = "Disk typ on for nodes in the Saxml admin node pool"
    default = "pd-standard"
}

variable "saxml_converter_pool_node_count" {
    description = "The number of nodes in the Saxml converter node pool"
    default     = 3
}

variable "saxml_converter_pool_machine_type" {
    description = "The machine type for the Saxml converter node pool"
    default = "n2-highmem-32"
}

variable "saxml_converter_pool_disk_size" {
    description = "Disk size for nodes in the Saxml converter node pool"
    default = 200
}

variable "saxml_converter_pool_disk_type" {
    description = "Disk typ on for nodes in the Saxml converter node pool"
    default = "pd-standard"
}

variable "saxml_sa_name" {
    description = "The service account name for Saxml workload identity."
    default = "saxml-sa"
}

variable "saxml_sa_roles" {
  description = "The roles to assign to the Saxml service account"
  default = [
    "roles/storage.objectAdmin",
    ] 
}


variable "saxml_namespace" {
    description = "The K8s namespace for the Saxml deployment."
    default = "saxml"
}


variable "network_name" {
    description = "The network name"
    type        = string
}

variable "subnet_name" {
    description = "The subnet name"
    type        = string
}

variable "subnet_ip_range" {
  description = "The IP address range for the subnet"
  default     = "10.129.0.0/20"
}

variable "pods_ip_range" {
    description = "The secondary IP range for pods"
    default     = "192.168.64.0/20"
}

variable "services_ip_range" {
    description = "The secondary IP range for services"
    default     = "192.168.80.0/20"
}

variable "max_pods_per_node" {
    description = "The maximum number of pods to schedule per node"
    default     = 110 
}

variable "gke_sa_name" {
    description = "The service account name for GKE node pools"
    default = "gke-sa"
}

variable "gke_sa_roles" {
  description = "The roles to assign to the GKE service account"
  default = [
    "storage.objectAdmin",
    "logging.logWriter",
    "aiplatform.user",
    ] 
}

variable "gke_release_channel" {
    description = "GKE release channel"
    default = "STABLE"
}

variable "gke_version" {
    description = "GKE version"
    default      = "1.27.3-gke.100"
}

variable "asm_release_channel" {
    description = "GKE release channel"
    default = "stable"
}

variable "tpu_machine_type" {
    description = "TPU machine type"
    default = "ct4p-hightpu-4t"
}

variable "tpu_type" {
    description = "TPU type"
    default = "v4-16"
}

variable "tpu_node_pool_name_prefix" {
    description = "TPU node pools name prefix"
    default = "tpu-node-pool" 
}

variable "num_tpu_pools" {
    description = "Number of TPU slices to create"
    default = 1 
}

variable "enable_tpu_autoscaling" {
    description = "Enable TPU autoscaling"
    default = false 
}


