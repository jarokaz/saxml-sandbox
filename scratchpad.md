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

docker pull $SAX_ADMIN_SERVER_IMAGE_URL 
docker pull $SAX_MODEL_SERVER_IMAGE_URL
docker pull $SAX_UTIL_IMAGE_URL

export SAX_ADMIN_SERVER_DOCKER_NAME="sax-admin-server"
export SAX_MODEL_SERVER_DOCKER_NAME="sax-model-server"
export SAX_CELL="/sax/test"
export SAX_ADMIN_STORAGE_BUCKET=jk-sax-admin-bucket
export SAX_DATA_STORAGE_BUCKET=jk-aiml-repository

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


## Running saxutil from admin server
```
CHECKPOINT_PATH=gs://jk-saxml-model-repository/gptj-pax-1/checkpoint_00000000
SAX_ROOT=gs://jk-saxml-admin-bucket/sax-root
SAX_CELL=/sax/test
MODEL_NAME=gptjtokenizedbf16bs32
MODEL_CONFIG_PATH=saxml.server.pax.lm.params.gptj.GPTJ4TokenizedBF16BS32
REPLICA=1

```
### List models

```
saxutil ls $SAX_CELL
```

### Publish a model
```

saxutil \
--sax_root=$SAX_ROOT \
publish \
${SAX_CELL}/${MODEL_NAME} \
${MODEL_CONFIG_PATH} \
${CHECKPOINT_PATH} \
${REPLICA}
```

### Run inference

```
INPUT_STR="21106,318,281,12064,326,8477,257,4876,11,20312,351,281,5128,326,3769,2252,4732,13,19430,257,2882,326,20431,32543,262,2581,13,198,198,21017,46486,59,25,198,13065,3876,1096,262,1708,1705,2708,59,25,198,198,21017,23412,59,25,198,16192,838,11,1853,764,775,821,4988,3230,287,8354,319,3431,13,775,821,10013,8031,11,3284,11,262,1578,4498,24880,11,290,262,42438,22931,21124,13,9938,503,508,338,9361,284,2498,4182,615,10055,262,13342,287,257,6614,13232,12387,416,262,4252,11,290,7301,262,11428,5585,286,1067,8605,287,7840,7229,13,921,1183,635,651,257,1570,286,5628,41336,326,373,4271,10395,329,39311,13,1550,428,2443,345,481,1064,1909,338,905,42978,290,257,1295,329,345,284,2581,284,307,319,262,8100,13613,3000,8299,4889,13,48213,6173,46023,764,6914,994,284,1895,262,14687,286,1909,338,8100,13613,3000,1430,13,4222,3465,326,612,743,307,257,5711,1022,262,640,618,262,2008,318,1695,290,618,262,14687,318,3199,13,8100,13613,3000,318,2727,416,257,1074,286,9046,508,2074,262,8070,7231,1812,20130,11,2260,5423,287,1180,2426,3006,11,290,1181,5423,618,9194,262,905,13,15107,3069,42815,764,1114,257,2863,284,307,4750,319,262,1306,8100,13613,3000,11,2912,319,262,4220,286,428,2443,351,534,1524,1438,11,37358,11,1748,290,1181,13,775,481,307,17246,4266,422,262,3651,286,262,2180,905,13,921,1276,307,257,4701,393,257,3710,2479,1511,393,4697,284,2581,257,3068,319,262,8100,13613,3000,8299,4889,0,6952,345,329,1262,8100,13613,3000,0,198,198,21017,18261,59,25"

saxutil \
--sax_root=$SAX_ROOT \
lm.generate \
${SAX_CELL}/${MODEL_NAME} \
${INPUT_STR}
```


### Unpublish a model

```
saxutil \
--sax_root=$SAX_ROOT \
unpublish \
${SAX_CELL}/${MODEL_NAME} 
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

export GSBUCKET=jk-saxml-admin-bucket
export ADMIN_SERVER_IMAGE=us-docker.pkg.dev/cloud-tpu-images/inference/sax-admin-server:v1.1.0

docker run -d --rm --network "host" \
-e GSBUCKET=$GSBUCKET \
$ADMIN_SERVER_IMAGE

```

### Starting a model server container on a TPU VM

```
export GSBUCKET=jk-saxml-admin-bucket
export SAX_ROOT=gs://$GSBUCKET/sax-root
export MODEL_SERVER_IMAGE=us-docker.pkg.dev/cloud-tpu-images/inference/sax-model-server:v1.1.0
export SAX_CELL=/sax/test
export MODEL_SERVER_PORT=10001
export TPU_CHIP=tpuv4
export TPU_TOPOLOGY="2x2x1"

docker run -d  --rm  --privileged --network host \
-e SAX_ROOT=$SAX_ROOT \
$MODEL_SERVER_IMAGE \
--sax_cell=$SAX_CELL \
--port=$MODEL_SERVER_PORT \
--platform_chip=$TPU_CHIP \
--platform_topology=$TPU_TOPOLOGY \
--jax_platforms=tpu


```

### start utility

```
export UTILITY_IMAGE=us-docker.pkg.dev/cloud-tpu-images/inference/sax-util:v1.1.0 

docker run -it --rm --entrypoint /bin/bash --network host \
--env SAX_ROOT=$SAX_ROOT \
$UTILITY_IMAGE
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


gcloud compute tpus tpu-vm create jk-saxml-tpu-model-server \
  --zone=us-central2-b \
  --accelerator-type=v4-8 \
  --version=tpu-vm-v4-base \
  --scopes=https://www.googleapis.com/auth/cloud-platform \
  --tags=saxml-model-server


## Get message schemal literal

```
sed -z -e 's/"/\\"/g' -e 's/\n/\\n/g' ../applications/locust_load_generator/src/common/metrics.proto

```