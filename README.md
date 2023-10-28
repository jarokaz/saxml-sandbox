# Saxml sandbox

## Setting up Saxml on GCE

### Create a service account

```
PROJECT_ID=jk-mlops-dev
SA_NAME=sax-sa

gcloud iam service-accounts create $SA_NAME \
    --description="A service account for Saxml cells" \
    --display-name="Saxml SA"
```

```
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/storage.admin"


gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/logging.logWriter"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/monitoring.metricWriter"
```



### Create ag GCE instance for the admin server

This can be a CPU-only machine

```
gcloud compute instances create jk-sax-admin \
  --zone=us-central1-b \
  --machine-type=e2-standard-8 \
  --boot-disk-size=200GB \
  --scopes=https://www.googleapis.com/auth/cloud-platform
```


### Create TPU workers

```
TPU_WORKER_NAME=jk-sax-model-1
ZONE=us-central2-b
TPU_TYPE=v4-8
RUNTIME=

gcloud alpha compute tpus queued-resources create $TPU_WORKER_NAME \
--node-id $TPU_WORKER_NAME \
--project $PROJECT_ID \
--zone  $ZONE \
--accelerator-type $TPU_TYPE \
--runtime-version tpu-vm-v4-base
```

```
gcloud compute tpus tpu-vm create jk-sax-tpu-01 \
  --zone=us-central2-b \
  --accelerator-type=v4-8 \
  --version=tpu-vm-v4-base \
  --scopes=https://www.googleapis.com/auth/cloud-platform
```

 ## Single host serving

 ### Start admin server

 ```
SAX_ADMIN_SERVER_IMAGE_NAME="us-docker.pkg.dev/cloud-tpu-images/inference/sax-admin-server"
SAX_MODEL_SERVER_IMAGE_NAME="us-docker.pkg.dev/cloud-tpu-images/inference/sax-model-server"
SAX_UTIL_IMAGE_NAME="us-docker.pkg.dev/cloud-tpu-images/inference/sax-util"

SAX_VERSION=v1.0.0

export SAX_ADMIN_SERVER_IMAGE_URL=${SAX_ADMIN_SERVER_IMAGE_NAME}:${SAX_VERSION}
export SAX_MODEL_SERVER_IMAGE_URL=${SAX_MODEL_SERVER_IMAGE_NAME}:${SAX_VERSION}
export SAX_UTIL_IMAGE_URL="${SAX_UTIL_IMAGE_NAME}:${SAX_VERSION}"
export SAX_ADMIN_SERVER_DOCKER_NAME="sax-admin-server"
export SAX_MODEL_SERVER_DOCKER_NAME="sax-model-server"
export SAX_CELL="/sax/test"
export SAX_ADMIN_STORAGE_BUCKET=jk-sax-admin-bucket
export SAX_DATA_STORAGE_BUCKET=jk-gke-aiml-repository

#docker run \
#--name ${SAX_ADMIN_SERVER_DOCKER_NAME} \
#-it \
#-d \
#--rm \
#--network host \
#--env GSBUCKET=${SAX_ADMIN_STORAGE_BUCKET} \
#${SAX_ADMIN_SERVER_IMAGE_URL}


docker run \
--name ${SAX_ADMIN_SERVER_DOCKER_NAME} \
-it \
--rm \
--network host \
--env GSBUCKET=${SAX_ADMIN_STORAGE_BUCKET} \
${SAX_ADMIN_SERVER_IMAGE_URL}
 ```

### Start a single-host model server

```
docker run \
    --privileged  \
    -it \
    --rm \
    --network host \
    --name ${SAX_MODEL_SERVER_DOCKER_NAME} \
    --env SAX_ROOT=gs://${SAX_ADMIN_STORAGE_BUCKET}/sax-root \
    ${SAX_MODEL_SERVER_IMAGE_URL} \
       --sax_cell=${SAX_CELL} \
       --port=10001 \
       --platform_chip=tpuv4 \
       --platform_topology=1x1

```

# Archive


## Running Saxml in Docker

### Build Saxml container image

```
export PROJECT_ID=jk-mlops-dev
export CONTAINER_REGISTRY_PREFIX=gcr.io/$PROJECT_ID

gcloud builds submit \
  --config build.yaml \
  --substitutions _CONTAINER_REGISTRY_PREFIX=$CONTAINER_REGISTRY_PREFIX \
  --timeout "16h" \
  --machine-type=e2-highcpu-32 \
  --quiet


```

### Starting an admin container

```
docker run -it --rm \
--env SAX_CELL=/sax/test \
--env GSBUCKET=jk-gke-aiml-repository \
--env PORT=10000 \
gcr.io/jk-mlops-dev/sax-admin
```

### Starting a model server container on a TPU VM

```
export GSBUCKET=jk-gke-aiml-repository

docker run -it --rm  --privileged \
--env SAX_ROOT=gs://${GSBUCKET}/sax-root \
gcr.io/jk-mlops-dev/sax-model \
--sax_cell=/sax/test \
--port=1001 \
--platform_chip=tpuv4 \
--platform_topology=2x2x1 

```


### Publish a modle

```
docker run gcr.io/jk-mlops-dev/sax-util --sax_root=gs://${GSBUCKET}/sax-root \
  publish \
  /sax/test/lm2b \
  saxml.server.pax.lm.params.lm_cloud.LmCloudSpmd2BTest \
  None \
  1
```

### Run a smoke test

```
docker run gcr.io/jk-mlops-dev/sax-util --sax_root=gs://${GSBUCKET}/sax-root \
  lm.generate \
  /sax/test/lm2b \
  "Q: Who is Harry Porter's mother? A: "

```