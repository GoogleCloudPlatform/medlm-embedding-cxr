#!/bin/bash

MODEL_NAME=cxr-model

# Make sure all our variables are defined!
while read var; do
  [ -z "${!var}" ] && { echo "Variable $var is not defined!"; exit 1; }
done << EOF
PROJECT_ID
CXR_LOCATION
VERTEX_ENDPOINT_ID
MODEL_BUCKET_NAME
MODEL_DIR
EOF

printf "***\n* Copying model to GCS bucket\n***\n"
gcloud storage cp --recursive $MODEL_DIR gs://$MODEL_BUCKET_NAME

printf "***\n* Uploading the model to Vertex AI Model Registry\n***\n"
gcloud ai models upload \
  --project=$PROJECT_ID \
  --region=$CXR_LOCATION \
  --display-name=$MODEL_NAME \
  --container-image-uri=us-docker.pkg.dev/vertex-ai/prediction/tf2-cpu.2-13:latest \
  --artifact-uri=gs://$MODEL_BUCKET_NAME/model
MODEL_ID=$(
    gcloud ai models list --project=$PROJECT_ID --region=$CXR_LOCATION | grep $MODEL_NAME | awk '{print $1}' | head -1
)

printf "***\n* Hosting the model on a Vertex AI endpoint\n***\n"
gcloud ai endpoints deploy-model $VERTEX_ENDPOINT_ID \
  --project=$PROJECT_ID \
  --region=$CXR_LOCATION \
  --model=$MODEL_ID \
  --display-name=$MODEL_NAME \
  --traffic-split=0=100