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