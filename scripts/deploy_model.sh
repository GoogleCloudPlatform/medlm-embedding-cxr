#!/bin/bash

MODEL_NAME=cxr-model

# Make sure all our variables are defined!
while read var; do
  [ -z "${!var}" ] && { echo "Variable $var is not defined!"; exit 1; }
done << EOF
PROJECT_ID
LOCATION
VERTEX_ENDPOINT_ID
MODEL_BUCKET_NAME
MODEL_DIR
EOF

echo Copying model to GCS bucket
gsutil cp -r $MODEL_DIR gs://$MODEL_BUCKET_NAME

echo Uploading the model to Vertex AI Model Registry
gcloud ai models upload \
  --project=$PROJECT_ID \
  --region=$LOCATION \
  --display-name=$MODEL_NAME \
  --container-image-uri=us-docker.pkg.dev/vertex-ai/prediction/tf2-cpu.2-13:latest \
  --artifact-uri=gs://$MODEL_BUCKET_NAME/model
MODEL_ID=$(
    gcloud ai models list --project=$PROJECT_ID --region=$LOCATION | grep $MODEL_NAME | awk '{print $1}' | head -1
)
echo ModelID: $MODEL_ID

echo Hosting the model on a Vertex AI endpoint
gcloud ai endpoints deploy-model $VERTEX_ENDPOINT_ID \
  --project=$PROJECT_ID \
  --region=$LOCATION \
  --model=$MODEL_ID \
  --display-name=$MODEL_NAME \
  --traffic-split=0=100