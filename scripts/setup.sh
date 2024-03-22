#!/bin/bash

# Make sure all our variables are defined!
while read var; do
  [ -z "${!var}" ] && { echo "Variable $var is not defined!"; exit 1; }
done << EOF
PROJECT_ID
LOCATION
DATASET_ID
STORE_ID
BQ_TABLE_ID
VERTEX_ENDPOINT_ID
MODEL_BUCKET_NAME
EOF

# Python packages
printf "***\n* Installing python packages\n***\n"
pip install db-dtypes google-cloud-bigquery pydicom scikit-learn "tf-models-official==2.14.0" > /dev/null # only errs

# Retrieve terraform executable and scripts locally
TF_URL=https://releases.hashicorp.com/terraform/1.6.1/terraform_1.6.1_linux_amd64.zip
if ! test -f terraform; then
    echo Retrieving terraform executable
    curl -so terraform.zip ${TF_URL}
    unzip terraform.zip
    rm -rf terraform.zip
fi

# Label the environment, if it is GCE
STATUS_CODE=$(curl --write-out %{http_code} --silent --output /dev/null metadata)
if [[ "${STATUS_CODE}" -eq 200 ]]; then
    VMNAME=$(curl -H Metadata-Flavor:Google metadata/computeMetadata/v1/instance/hostname | cut -d. -f1)
    ZONE=$(curl -H Metadata-Flavor:Google metadata/computeMetadata/v1/instance/zone | cut -d/ -f4)
    gcloud compute instances update ${VMNAME} --zone=${ZONE} --update-labels=goog-packaged-solution=medical-imaging-suite
    echo "Set label on ${VMNAME}"
else
    echo "Skipping label since not inside a GCE instance."
fi

# Deploy terraform
printf "***\n* Deploying terraform resources\n***\n"
./terraform -chdir=./tf init
./terraform -chdir=./tf plan -var="project_id=$PROJECT_ID" -var="location=$LOCATION" -var="dataset_id=$DATASET_ID" -var="store_id=$STORE_ID" -var="table_id=$BQ_TABLE_ID" -var="vertex_endpoint_name=$VERTEX_ENDPOINT_ID" -var="gcs_bucket_name=$MODEL_BUCKET_NAME" -out tf.plan
./terraform -chdir=./tf apply tf.plan

# NOTE: If you want to explore all variations of labeled images from the NIH Chest X-ray dataset, please feel free to ingest all using the following:
# gcloud healthcare dicom-stores import gcs $STORE_ID --dataset=$DATASET_ID --project=$PROJECT_ID --location=$LOCATION --gcs-uri="gs://cxr-foundation-demo/cxr14/inputs/*.dcm"

# Import into Healthcare API, so embeddings API can access DICOM images
printf "***\n* Importing studies in to Healthcare API DICOM Store\n***\n"
gcloud healthcare dicom-stores import gcs $STORE_ID --dataset=$DATASET_ID --project=$PROJECT_ID --location=$LOCATION --gcs-uri="gs://mis-ai-accelerator/data/staged/inputs/*.dcm"

# Create directory tree for output
mkdir -p data/outputs/model