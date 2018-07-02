provider "google" {
  region      = "${var.gc_region}"
  project     = "${var.google_project}"
  # credentials = "${file("~/gcloud-service-key.json")}"
}