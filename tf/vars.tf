variable "project_id" {
 type = string
 default = "myproject"
}

variable "location" {
 type = string
 default = "us-central1"
}

variable "dataset_id" {
 type = string
 default = "pneumothorax"
}

variable "store_id" {
 type = string
 default = "trainingdata"
}

variable "table_id" {
 type = string
 default = "metadata"
}

variable "vertex_endpoint_name" {
 type = string
 default = "vertex-endpoint"
}

variable "gcs_bucket_name" {
 type = string
 default = "model-bucket"
}

variable "api_list" {
  description ="APIs to enable on the project"
  type = list(string)
  default = [
    "healthcare.googleapis.com",
    "bigquery.googleapis.com",
    "notebooks.googleapis.com",
    "aiplatform.googleapis.com"
  ]
}
