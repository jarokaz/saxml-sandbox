## Inferencing on GPTJ-6B model

### Download the GTPJ-6B checkpoint

Download the checkpoint and stage it to GCS. Checkpoint location

`https://cloud.mlcommons.org/index.php/s/QAZ2oM94MkFtbQx/download`


### Convert the checkpoint

```
PROJECT_ID=jk-mlops-dev
GPTJ_6B_CHECKPOINT=gs://jk-saxml-archive/checkpoints/gpt-j
GPTJ_6B_PAX_CHECKPOINT=gs://jk-saxml-model-repository/checkpoints/gptj-6b-pax
MACHINE_TYPE=e2-highmem-16


gcloud builds submit \
--project $PROJECT_ID \
--config convert_gptj_checkpoint.yaml \
--substitutions _SOURCE_CHECKPOINT_PATH=$GPTJ_6B_CHECKPOINT,_DESTINATION_CHECKPOINT_PATH=$GPTJ_6B_PAX_CHECKPOINT \
--machine-type=$MACHINE_TYPE \
--quiet
```