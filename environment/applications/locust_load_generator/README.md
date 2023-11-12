

```
docker run -it --rm --entrypoint /bin/bash --network host \
-v /home/jarekk//saxml-sandbox/environment/applications/locust_load_generator/src:/src \
-e HUGGINGFACE_TOKEN=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 \
-e SAX_ROOT=gs://jk-saxml-admin-bucket/sax-root \
gcr.io/jk-mlops-dev/locust-load-generator
```


### Setting firewall rules to access GCE saxml from GKE

```
SOURCE_RANGE="192.168.64.0/20"
CLUSTER_NAME=jk-saxml-cluster
PROJECT_ID=jk-mlops-dev

gcloud compute --project=$PROJECT_ID firewall-rules create \
--direction=INGRESS --priority=1000 \
--network=default



```

