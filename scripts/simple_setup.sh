#!/bin/bash

# Make sure all our variables are defined!
while read var; do
  [ -z "${!var}" ] && { echo "Variable $var is not defined!"; exit 1; }
done << EOF
PROJECT_ID
LOCATION
DICOM_DATASET_ID
DICOM_STORE_ID
IMPORT_GCS_URI
MODEL_BUCKET_NAME
VERTEX_ENDPOINT_ID
EOF

# Python packages
printf "***\n* Installing python packages\n***\n"
pip install pydicom scikit-learn "tf-models-official==2.14.0" > /dev/null # only errs

# Create Model Bucket
printf "***\n* Creating and GCS Bucket to store trained model artifacts\n***\n"
gcloud storage buckets create $MODEL_BUCKET_NAME --project=$PROJECT_ID

# Create and populate DICOM store
printf "***\n* Creating and populating Test DICOM Store\n***\n"
gcloud healthcare datasets create $DICOM_DATASET_ID --project=$PROJECT_ID --location=$LOCATION
gcloud healthcare dicom-stores create $DICOM_STORE_ID --project=$PROJECT_ID --location=$LOCATION --dataset=$DICOM_DATASET_ID
gcloud healthcare dicom-stores import gcs $DICOM_STORE_ID --project=$PROJECT_ID --location=$LOCATION --dataset=$DICOM_DATASET_ID --gcs-uri=$IMPORT_GCS_URI

# Create Vertex AI Endpoint
printf "***\n* Creating Vertex AI Endpoint for hosting trained model.\n***\n"
gcloud ai endpoints create --project=$PROJECT_ID --region=$LOCATION --display-name=$VERTEX_ENDPOINT_ID --endpoint-id=$VERTEX_ENDPOINT_ID

# Create directory tree for output
printf "***\n* Creating directory tree for output.\n***\n"
mkdir -p data/outputs/model