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


#resource "google_compute_instance" "saxml-admin" {
#    name = "jk-saxml-admin-test"
#    machine_type = "n1-standard-8"
#    zone = var.zone
#
#    boot_disk {
#        initialize_params {
#            image = "debian-cloud/debian-11"
#            size = 500
#            type = "pd-standard"
#        }
#    }
#
#    network_interface {
#        network = google_compute_network.cluster_network.name
#        subnetwork = google_compute_subnetwork.cluster_subnetwork.name
#
#        access_config {
#        // Ephemeral public IP
#        }
#    }
#
#    service_account {
#        email  = google_service_account.gke_service_account.email
#        scopes = ["cloud-platform"]
#    }
#}



#resource google_tpu_v2_vm "saxml-model-server" {
#    provider = google-beta
#    name = "jk-saxml-model-server-test"
#    zone = var.zone
#    runtime_version = "tpu-vm-v4-base"
#
#    accelerator_config {
#        type     = "V4"
#        topology = "2x2x1"
#    }
#
#    network_config {
#        can_ip_forward      = true
#        enable_external_ips = true
#        network             = google_compute_network.cluster_network.name
#        subnetwork          = google_compute_subnetwork.cluster_subnetwork.name
#    }
#}
#
#