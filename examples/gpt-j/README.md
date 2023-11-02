## Inferencing on GPTJ-6B model

### Download the GTPJ-6B checkpoint

Download the checkpoint and stage it to GCS. Checkpoint location

`https://cloud.mlcommons.org/index.php/s/QAZ2oM94MkFtbQx/download`


### Convert the checkpoint

Update the  `converter-parameters configMapGenerater` in  the `convert_checkpoint\kustomization.yaml` file as follows:
- Set `GCS_BASE_CHECKPOINT_PATH` to the GCS location of the GTPJ-6B checkpoint you downloaded in the previous
- Set `GCS_PAX_CHECKPOINT_PATH` to the GCS location where you want to store the converted checkpoint. 

Start the conversion job:

```
kubectl apply -k convert_checkpoint
```