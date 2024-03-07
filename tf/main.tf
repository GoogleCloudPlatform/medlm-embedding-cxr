provider "google" {
  project = var.project_id
  region  = var.location
}

data "google_project" "project" {
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

resource "google_project_service" "enable" {
  for_each = toset(var.api_list)
  service = each.key
}

resource "google_healthcare_dicom_store" "default" {
  provider = google-beta

  name    = var.store_id
  dataset = google_healthcare_dataset.default.id

  labels = {
    goog-packaged-solution = "medical-imaging-suite"
  }

  stream_configs {
    bigquery_destination {
      table_uri = "bq://${google_bigquery_dataset.default.project}.${google_bigquery_dataset.default.dataset_id}.${google_bigquery_table.default.table_id}"
    }
  }

  depends_on = [
    google_project_iam_binding.gcp-sa-healthcare
   ]
}

resource "google_healthcare_dataset" "default" {
  name     = var.dataset_id
  location = var.location

  depends_on = [
    google_project_service.enable
   ]
}

resource "google_bigquery_dataset" "default" {
  dataset_id                 = var.dataset_id
  location                   = var.location
  delete_contents_on_destroy = true

  depends_on = [
    google_project_service.enable
   ]
}

resource "google_bigquery_table" "default" {
  labels = {
    goog-packaged-solution = "medical-imaging-suite"
  }

  deletion_protection = false
  dataset_id          = google_bigquery_dataset.default.dataset_id
  table_id            = var.table_id
}

resource "google_vertex_ai_endpoint" "default" {
  labels = {
    goog-packaged-solution = "medical-imaging-suite"
  }

  name         = var.vertex_endpoint_name
  display_name = "MedLM Endpoint"
  location     = var.location

  depends_on = [
    google_project_service.enable
   ]
}

resource "google_storage_bucket" "default" {
  labels = {
    goog-packaged-solution = "medical-imaging-suite"
  }

  name          = var.gcs_bucket_name
  location      = var.location
  force_destroy = true

  uniform_bucket_level_access = true
}

resource "google_project_iam_binding" "gcp-sa-aiplatform" {
  project = data.google_project.project.number
  role = "roles/healthcare.dicomViewer"
  members = [
    "serviceAccount:service-${data.google_project.project.number}@gcp-sa-aiplatform.iam.gserviceaccount.com",
  ]
  depends_on = [ google_vertex_ai_endpoint.default ]
}

resource "google_project_iam_binding" "gcp-sa-healthcare" {
  project = data.google_project.project.number
  role = "roles/bigquery.dataEditor"
  members = [
    "serviceAccount:service-${data.google_project.project.number}@gcp-sa-healthcare.iam.gserviceaccount.com",
  ]
  depends_on = [ google_healthcare_dataset.default ]
}

