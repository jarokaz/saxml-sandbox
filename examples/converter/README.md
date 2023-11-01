# Build a docker container image for checkpoint converter

```
PROJECT_ID=jk-mlops-dev
IMAGE_URI=gcr.io/$PROJECT_ID/checkpoint_converter
MACHINE_TYPE=e2-highcpu-8


gcloud builds submit \
--project $PROJECT_ID \
--config build.yaml \
--substitutions _CONVERTER_IMAGE_URI=$IMAGE_URI \
--machine-type=$MACHINE_TYPE \
--quiet

```