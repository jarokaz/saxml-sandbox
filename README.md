# Saxml sandbox

## Setting up Saxml on GCE

### Create ag GCE instance for the admin server

This can be a CPU-only machine

```
gcloud compute instances create jk-sax-admin \
  --zone=us-central1-b \
  --machine-type=e2-standard-8 \
  --boot-disk-size=200GB \
  --scopes=https://www.googleapis.com/auth/cloud-platform
```


```

gcloud compute tpus tpu-vm create jk-sax-tpu \
  --zone=us-central2-b \
  --accelerator-type=v4-8 \
  --version=tpu-vm-v4-base \
  --scopes=https://www.googleapis.com/auth/cloud-platform
```


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

### Starting a model server container

```
docker run -it --rm \
gcr.io/jk-mlops-dev/sax-model \
--sax_cell=/sax/test \
--port=1001 \
--platform_chip=tpuv4 \
--platform_topology=2x2x1 
```