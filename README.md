# Deploying Saxml on Google Kubernetes Engine 

This reference guide introduces a reference architecture for deploying [Saxml](https://github.com/google/saxml) on [Google Kubernetes Engine (GKE)](https://cloud.google.com/kubernetes-engine?hl=en) and offers comprehensive guidelines for serving  models developed in  Paxml, JAX, and PyTorch on Cloud TPU v5e, including the Llama2 series.

## Saxml on GKE high level architecture  

The diagram below depicts a high-level architecture of the Saxml system on Google Kubernetes Engine.

![arch](/images/saxml-gke.png)

## Saxml deployment configuration

WIP

## Environment setup

WIP

### Initialize Terraform

```
export TF_STATE_BUCKET=jk-mlops-dev-tf-state
export TF_STATE_PREFIX=gke-tpu-serving-environment

terraform init -backend-config="bucket=$TF_STATE_BUCKET" -backend-config="prefix=$TF_STATE_PREFIX"

```

### Apply configuration

```
export PROJECT_ID=jk-mlops-dev
export REGION=us-central2
export ZONE=us-central2-b
export SAXML_ADMIN_BUCKET_NAME=jk-saxml-admin-bucket
export MODEL_REPOSITORY_BUCKET_NAME=jk-saxml-model-repository
export NETWORK_NAME=jk-gke-network
export SUBNET_NAME=jk-gke-subnet
export CLUSTER_NAME=jk-saxml-cluster
export NAMESPACE=saxml

terraform apply \
-var=project_id=$PROJECT_ID \
-var=cluster_name=$CLUSTER_NAME \
-var=region=$REGION \
-var=zone=$ZONE \
-var=network_name=$NETWORK_NAME \
-var=subnet_name=$SUBNET_NAME \
-var=saxml_namespace=$NAMESPACE \
-var=repository_bucket_name=$MODEL_REPOSITORY_BUCKET_NAME \
-var=saxml_admin_bucket_name=$SAXML_ADMIN_BUCKET_NAME 

```




## Serving workloads examples

WIP

