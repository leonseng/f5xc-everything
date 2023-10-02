locals {
  gcp_inside_cidr  = cidrsubnet(var.gcp_inside_vpc_cidr, 8, 1)
  gcp_outside_cidr = cidrsubnet(var.gcp_outside_vpc_cidr, 8, 1)
  gcp_vm_cidr      = cidrsubnet(var.gcp_inside_vpc_cidr, 8, 2)
}

resource "google_compute_network" "inside" {
  name                    = "${local.name_prefix}-inside"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "inside" {
  name          = "${local.name_prefix}-inside"
  ip_cidr_range = local.gcp_inside_cidr
  region        = var.gcp_region
  network       = google_compute_network.inside.name
}

resource "google_compute_network" "outside" {
  name                    = "${local.name_prefix}-outside"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "outside" {
  name          = "${local.name_prefix}-outside"
  ip_cidr_range = local.gcp_outside_cidr
  region        = var.gcp_region
  network       = google_compute_network.outside.name
}

data "google_compute_zones" "available" {}

# workload
resource "google_compute_subnetwork" "vm" {
  name          = "${local.name_prefix}-inside-vm"
  ip_cidr_range = local.gcp_vm_cidr
  network       = google_compute_network.inside.name
  region        = var.gcp_region
}

resource "google_compute_firewall" "vm-ingress" {
  name               = "${local.name_prefix}-vm-ingress"
  direction          = "INGRESS"
  network            = google_compute_network.inside.name
  destination_ranges = ["0.0.0.0/0"]
  source_ranges      = [local.aws_vm_cidr, local.gcp_inside_cidr]
  target_tags        = ["${local.name_prefix}-vm"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "5201"]
  }

  # iperf UDP
  allow {
    protocol = "udp"
    ports    = ["5201"]
  }


  allow {
    protocol = "icmp"
  }
}

resource "google_compute_firewall" "vm-ingress-external" {
  name               = "${local.name_prefix}-vm-ingress-external"
  direction          = "INGRESS"
  network            = google_compute_network.inside.name
  destination_ranges = [local.gcp_vm_cidr]
  source_ranges      = [local.my_ip]
  target_tags        = ["${local.name_prefix}-vm"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "80"]
  }

  allow {
    protocol = "icmp"
  }
}

resource "google_compute_firewall" "vm-egress" {
  name               = "${local.name_prefix}-vm-egress"
  direction          = "EGRESS"
  network            = google_compute_network.inside.name
  destination_ranges = ["0.0.0.0/0"]
  target_tags        = ["${local.name_prefix}-vm"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }

  allow {
    protocol = "all"
  }
}

data "google_compute_image" "ubuntu_image" {
  family  = "ubuntu-2004-lts"
  project = "ubuntu-os-cloud"
}

resource "google_compute_instance" "vm" {
  count = var.gcp_zone_count

  name         = "${local.name_prefix}-vm-${count.index + 1}"
  machine_type = var.gcp_vm_machine_type
  zone         = data.google_compute_zones.available.names[count.index]
  tags         = ["${local.name_prefix}-vm", "${local.name_prefix}-vm-${count.index + 1}"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu_image.self_link
    }
  }

  network_interface {
    network    = google_compute_network.inside.name
    subnetwork = google_compute_subnetwork.vm.name
    access_config {}
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_public_key}"
    user-data = templatefile("${path.module}/files/vm/cloud-config", {
      run_script = base64encode(file("${path.module}/files/vm/run.sh"))
      nginx_conf = base64encode(file("${path.module}/files/vm/nginx.conf"))
    })
  }
}

output "gcp_inside_vpc_id" {
  value = google_compute_network.inside.id
}

output "gcp_inside_subnet" {
  value = google_compute_subnetwork.inside.id
}

output "gcp_outside_vpc_id" {
  value = google_compute_network.outside.id
}

output "gcp_outside_subnet" {
  value = google_compute_subnetwork.outside.id
}

output "gcp_vms" {
  value = [for vm in google_compute_instance.vm : {
    zone       = vm.zone,
    private_ip = vm.network_interface[0].network_ip,
    ssh_cmd    = "ssh ubuntu@${vm.network_interface[0].access_config[0].nat_ip}"
  }]
}
