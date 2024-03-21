#!/bin/bash

# Make sure all our variables are defined!
while read var; do
  [ -z "${!var}" ] && { echo "Variable $var is not defined!"; exit 1; }
done << EOF
PROJECT_ID
LOCATION
VERTEX_ENDPOINT_ID
EOF

# Python packages
printf "***\n* Installing python packages\n***\n"
pip install pydicom scikit-learn "tf-models-official==2.14.0" > /dev/null # only errs

# Create Vertex AI Endpoint
gcloud ai endpoints create --project=$PROJECT_ID --region=$LOCATION --display-name=$VERTEX_ENDPOINT_ID --endpoint-id=$VERTEX_ENDPOINT_ID
# Create directory tree for output
mkdir -p data/outputs/model