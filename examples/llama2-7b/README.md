# Deploying  Llama-2 7B model

## Download the GTPJ-6B checkpoint

Follow the instructions on [Llama 2 repo](https://github.com/facebookresearch/llama/blob/main/README.md) to access Llama 2 checkpoints. Download the checkpoints to a GCS location.


## Convert the checkpoint

Update the  `converter-parameters configMapGenerater` in  the `convert_checkpoint\kustomization.yaml` file as follows:
- Set `GCS_BASE_CHECKPOINT_PATH` to the GCS location of the GTPJ-6B checkpoint you downloaded in the previous step
- Set `GCS_PAX_CHECKPOINT_PATH` to the GCS location where you want to store the converted checkpoint. 
- Update `ARGS="--model-size=7b"` to specify the model size for the checkpoint to be converted

Start the conversion job:

```
kubectl apply -k convert_checkpoint
```

## Publish the model


List pods

```
kubectl get pods -n <YOUR NAMESPACE>
```

Execute shell on the server

```
kubectl exec -it <SAX ADMIN POD> -n <YOUR NAMESPACE> -- /bin/bash
```

### Publish the model

#### Set parameters

```
CHECKPOINT_PATH=gs://CHECKPOINT_PATH
CHECKPOINT_PATH=gs://jk-saxml-model-repository/pax-llama-7b/checkpoint_00000000
SAX_ROOT=gs://SAX_ADMIN_BUCKET/sax-root
SAX_ROOT=gs://jk-saxml-admin-bucket/sax-root
SAX_CELL=/sax/test

MODEL_NAME=llama7bfp16tpuv4
MODEL_CONFIG_PATH=saxml.server.pax.lm.params.lm_cloud.LLaMA7BFP16TPUv4
REPLICA=1
```

#### List published models

```
saxutil ls $SAX_CELL

```

#### Publish model

```
saxutil \
--sax_root=$SAX_ROOT \
publish \
${SAX_CELL}/${MODEL_NAME} \
${MODEL_CONFIG_PATH} \
${CHECKPOINT_PATH} \
${REPLICA}
```
o```
saxutil \
--sax_root=$SAX_ROOT \
publish \
${SAX_CELL}/${MODEL_NAME} \
${MODEL_CONFIG_PATH} \
${CHECKPOINT_PATH} \
${REPLICA} \
test_mode=false
```




This may take a while. Monitor the model server pod till the model loading is completed. 

```
kubectl logs <SAX MODEL SERVER POD> -n <YOUR NAMESPACE>
```

Wait till you see a similar message:

```
I1102 14:15:00.962680 134004674082368 servable_model.py:697] loading completed.
```

#### Run smoke test

```
INPUT_STR="21106,318,281,12064,326"

saxutil \
--sax_root=$SAX_ROOT \
lm.generate \
${SAX_CELL}/${MODEL_NAME} \
${INPUT_STR}
```

If successful the above command should return a list of tokens representing prompt completion. You should see the output similar to:

```
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+--------------+
|                                                                                                                                                    GENERATE                                                                                                                                                    |    SCORE     |
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+--------------+
| 770,2443,3407,262,905,42978,764,198,11041,262,42978,284,1037,2444,351,3555,35915,290,25818,764,198,2953,262,4220,286,262,2443,11,2912,329,257,2863,284,307,4750,319,8100,13613,3000,13,220,921,1276,307,257,4701,393,257,3710,2479,1511,393,4697,284,2581,257,3068,319,262,8100,13613,3000,8299,4889,13,50256  | -0.098845139 |
| 1212,2443,3407,262,905,42978,764,198,11041,262,42978,284,1037,2444,351,3555,35915,290,25818,764,198,2953,262,4220,286,262,2443,11,2912,329,257,2863,284,307,4750,319,8100,13613,3000,13,220,921,1276,307,257,4701,393,257,3710,2479,1511,393,4697,284,2581,257,3068,319,262,8100,13613,3000,8299,4889,13,50256 |  -0.46423212 |
| 770,2443,3407,262,905,42978,764,198,11041,262,42978,284,1037,2444,351,3555,35915,290,25818,764,198,2953,262,4220,286,262,2443,11,2912,329,257,2863,284,307,4750,319,8100,13613,3000,13,220,921,1276,307,257,4701,393,257,3710,2479,1511,393,4697,284,2581,257,3068,319,262,8100,13613,3000,8299,4889,0,50256   |  -0.92778915 |
| 383,4445,14687,318,257,3194,2196,286,1123,1110,338,8100,13613,3000,1430,764,198,11041,428,14687,284,1037,2444,351,3555,35915,290,25818,764,198,11041,262,10273,3000,421,528,284,1332,534,3725,286,3923,345,2497,319,8100,13613,3000,764,50256                                                                  |   -1.1044891 |
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+--------------+
```

#### Unpublish the model


To unpublish the model

```
saxutil \
--sax_root=$SAX_ROOT \
unpublish \
${SAX_CELL}/${MODEL_NAME} 
```