variable "cluster_name" {
  default = "insights-gc"
}

variable "instance_type" {
  default = "n1-standard-8"
}

variable "gc_zone" {
  default = "us-east1-b"
}

variable "cluster_size" {
  default = 4
}

variable "subnet" {}

variable "CHEF_CLIENT_NAME" {}
variable "CHEF_VALIDATION_KEY" {}
variable "CHEF_SERVER_URL" {}

variable "chef_env" {
  default = "google-compute"
}

variable "role" {}

variable "hostname" {}
