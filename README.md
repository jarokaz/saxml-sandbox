# Deploying Saxml on Google Kubernetes Engine 

This reference guide introduces a reference architecture for deploying [Saxml](https://github.com/google/saxml) on [Google Kubernetes Engine (GKE)](https://cloud.google.com/kubernetes-engine?hl=en) and offers comprehensive guidelines for serving  models developed in  Paxml, JAX, and PyTorch on Cloud TPU v5e, including the Llama2 series.

## Saxml on GKE high level architecture  

The diagram below depicts a high-level architecture of the Saxml system on Google Kubernetes Engine.

![arch](/images/saxml-gke.png)

## Saxml deployment configuration

WIP

## Environment setup

### Provision infrastructure

WIP

#### Initialize Terraform

```
cd environment/infrastructure

export TF_STATE_BUCKET=jk-mlops-dev-tf-state
export TF_STATE_PREFIX=gke-tpu-serving-environment

terraform init -backend-config="bucket=$TF_STATE_BUCKET" -backend-config="prefix=$TF_STATE_PREFIX"

```

#### Apply configuration

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
export TPU_TYPE=v4-8
export NUM_TPU_POOLS=1

terraform apply \
-var=project_id=$PROJECT_ID \
-var=cluster_name=$CLUSTER_NAME \
-var=region=$REGION \
-var=zone=$ZONE \
-var=network_name=$NETWORK_NAME \
-var=subnet_name=$SUBNET_NAME \
-var=saxml_namespace=$NAMESPACE \
-var=repository_bucket_name=$MODEL_REPOSITORY_BUCKET_NAME \
-var=saxml_admin_bucket_name=$SAXML_ADMIN_BUCKET_NAME \
-var=tpu_type=$TPU_TYPE \
-var=num_tpu_pools=$NUM_TPU_POOLS

```

#### Destroy infrastructure

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
export TPU_TYPE=v4-8
export NUM_TPU_POOLS=1

terraform destroy \
-var=project_id=$PROJECT_ID \
-var=cluster_name=$CLUSTER_NAME \
-var=region=$REGION \
-var=zone=$ZONE \
-var=network_name=$NETWORK_NAME \
-var=subnet_name=$SUBNET_NAME \
-var=saxml_namespace=$NAMESPACE \
-var=repository_bucket_name=$MODEL_REPOSITORY_BUCKET_NAME \
-var=saxml_admin_bucket_name=$SAXML_ADMIN_BUCKET_NAME \
-var=tpu_type=$TPU_TYPE \
-var=num_tpu_pools=$NUM_TPU_POOLS

```

### Deploy Saxml on GKE application components 

```

cd environment/applications

PROJECT_ID=jk-mlops-dev
CONVERTER_IMAGE_URI=gcr.io/$PROJECT_ID/checkpoint-converter
MACHINE_TYPE=e2-highcpu-8
PAXML_VERSION=1.2.0
CLOUD_SDK_VERSION=google-cloud-cli-453.0.0-linux-x86_64.tar.gz


gcloud builds submit \
--project $PROJECT_ID \
--config build.yaml \
--substitutions _CONVERTER_IMAGE_URI=$CONVERTER_IMAGE_URI,_PAXML_VERSION=$PAXML_VERSION,_CLOUD_SDK_VERSION=$CLOUD_SDK_VERSION \
--machine-type=$MACHINE_TYPE \
--quiet

```



## Serving workloads examples

WIP

