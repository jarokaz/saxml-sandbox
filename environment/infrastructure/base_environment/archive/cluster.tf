

# google_client_config and kubernetes provider must be explicitly specified like the following.
data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google"
  project_id                 = data.google_project.project.project_id
  name                       = var.cluster_name
  release_channel            = var.gke_release_channel
  kubernetes_version         = var.gke_version
  region                     = var.region
  zones                      = [var.zone]
  network                    = local.network_name
  subnetwork                 = local.subnet_name
  network_project_id         = var.network_project_id
  ip_range_pods              = local.pods_ip_range_name
  ip_range_services          = local.services_ip_range_name
  default_max_pods_per_node  = var.max_pods_per_node
  remove_default_node_pool   = true
  initial_node_count         = 1
  http_load_balancing        = false
  network_policy             = false
  horizontal_pod_autoscaling = true
  filestore_csi_driver       = false
  create_service_account     = false
  service_account            = local.gke_service_account_email
  grant_registry_access      = true
  gcs_fuse_csi_driver        = true
  identity_namespace         = "${data.google_project.project.project_id}.svc.id.goog"
  logging_enabled_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  deletion_protection        = var.cluster_deletion_protection

  cluster_resource_labels = { "mesh_id" : "proj-${data.google_project.project.number}" }

  node_pools              = local.node_pools
  node_pools_oauth_scopes = local.node_pools_oauth_scopes
  node_pools_labels       = local.node_pools_labels
  node_pools_taints       = local.node_pools_taints

}


#resource "kubernetes_namespace" "saxml_namespace" {
#  metadata {
#    name = var.saxml_namespace
#  }
#}
#
#
#module "workload_identity" {
#  source       = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
#  project_id   = data.google_project.project.project_id
#  name         = var.saxml_sa_name 
#  namespace    = kubernetes_namespace.saxml_namespace.metadata[0].name 
#  roles        = var.saxml_sa_roles
#}


#module "asm" {
#  source                    = "terraform-google-modules/kubernetes-engine/google//modules/asm"
#  project_id                = data.google_project.project.project_id
#  cluster_name              = module.gke.name
#  cluster_location          = module.gke.location
#  enable_cni                = false
#  enable_fleet_registration = true
#  enable_mesh_feature       = false 
#  channel                   = var.asm_release_channel
#}



