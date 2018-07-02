// Configure the Google Cloud provider
resource "random_id" "id" {
  byte_length = 8
}

resource "google_compute_instance" "alpha_instance" {
  name         = "${var.hostname}${format("%02d", count.index+1)}"
  machine_type = "${var.instance_type}"
  zone         = "${var.gc_zone}"
  count        = "${var.cluster_size}"

  tags = ["${join("-", split("_", var.role))}", "${var.gc_zone}"]

  boot_disk {
    initialize_params {
      image = "alpha-base"
      size  = "100"
    }
  }

  // Local SSD disk
  scratch_disk {}

  network_interface {
    subnetwork = "${var.subnet}"

    #address = "${element(google_compute_address.acr.*.self_link, count.index)}"
    access_config {
      // Ephemeral IP
    }
  }

  metadata {
    role = "${var.role}"
  }

  service_account {
    scopes = ["cloud-platform"]
  }

  #provisioner "local-exec" {
  #  command = "gcloud compute ssh ${self.name} --zone=${self.zone}"
  #}

  provisioner "local-exec" {
    command = "yes | knife client delete ${self.name} || exit 0"
  }
  provisioner "local-exec" {
    command = "yes | knife node delete ${self.name} || exit 0"
  }
  provisioner "chef" {
    connection {
      user = "root"
      type = "ssh"
    }

    environment             = "${var.chef_env}"
    run_list                = ["role[${var.role}]"]
    node_name               = "${var.hostname}${format("%02d", count.index+1)}"
    recreate_client         = true
    server_url              = "${var.CHEF_SERVER_URL}"
    user_name               = "${var.CHEF_CLIENT_NAME}"
    user_key                = "${var.CHEF_VALIDATION_KEY}"
    fetch_chef_certificates = true
    secret_key              = "${file("~/.chef/encrypted_data_bag_secret")}"
    attributes_json         = "${file("${path.module}/chef_attributes.json")}"
  }
}

data "google_dns_managed_zone" "dns_zone" {
  name = "${var.dns_managed_zone}"
}

resource "google_dns_record_set" "alpha" {
  count = "${var.cluster_size}"
  name  = "${var.hostname}${format("%02d", count.index+1)}.${data.google_dns_managed_zone.dns_zone.dns_name}"
  type  = "A"
  ttl   = 300

  managed_zone = "${data.google_dns_managed_zone.dns_zone.name}"

  rrdatas = ["${element(google_compute_instance.alpha_instance.*.network_interface.0.access_config.0.assigned_nat_ip, count.index)}"]
}

output "hostnames" {
  value = "${google_dns_record_set.alpha.*.name}"
}

output "addresses" {
  value = "${google_compute_instance.alpha_instance.*.network_interface.0.access_config.0.assigned_nat_ip}"
}
