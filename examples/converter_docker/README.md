# Build a docker container image for checkpoint converter

```
PROJECT_ID=jk-mlops-dev
IMAGE_URI=gcr.io/$PROJECT_ID/checkpoint-converter
MACHINE_TYPE=e2-highcpu-8
PAXML_VERSION=1.2.0
CLOUD_SDK_VERSION=google-cloud-cli-453.0.0-linux-x86_64.tar.gz


gcloud builds submit \
--project $PROJECT_ID \
--config build.yaml \
--substitutions _CONVERTER_IMAGE_URI=$IMAGE_URI,_PAXML_VERSION=$PAXML_VERSION,_CLOUD_SDK_VERSION=$CLOUD_SDK_VERSION \
--machine-type=$MACHINE_TYPE \
--quiet

```