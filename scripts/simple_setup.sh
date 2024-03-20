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
pip install pydicom scikit-learn "tf-models-official==2.14.0" > /dev/null # only errs

# NOTE: If you want to explore all variations of labeled images from the NIH Chest X-ray dataset, please feel free to ingest all using the following:
# gcloud healthcare dicom-stores import gcs $STORE_ID --dataset=$DATASET_ID --project=$PROJECT_ID --location=$LOCATION --gcs-uri="gs://cxr-foundation-demo/cxr14/inputs/*.dcm"

# Import into Healthcare API, so embeddings API can access DICOM images
printf "***\n* Importing studies in to Healthcare API DICOM Store\n***\n"
gcloud healthcare dicom-stores import gcs $STORE_ID --dataset=$DATASET_ID --project=$PROJECT_ID --location=$LOCATION --gcs-uri="gs://mis-ai-accelerator/data/staged/inputs/*.dcm"

# Create directory tree for output
mkdir -p data/outputs/model