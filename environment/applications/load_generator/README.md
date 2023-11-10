# Load generator

## Create a secrete to store a Hugging Face token

```
kubectl create secret generic hugging-face --from-literal=token='YOUR_TOKEN' -n <YOUR NAMESPACE>
```

## Set test parameters

Update the `kubernetes-manifests/parameters.env` file with your test's parameters.

## Add a unique Job name suffix

```
cd kubernetes-manifests

JOB_ID=101

kustomize edit set namesuffix $JOB_ID
```

## Submit a job

```
kubectl apply -k .

```

## Review test results

The results of the test will be stored in the JSON file in the GCS location specified by the `OUTPUT_LOCATION` parameter.

