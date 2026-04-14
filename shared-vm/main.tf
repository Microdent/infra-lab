terraform {
  required_version = ">= 1.6"
  required_providers {
    google = {
      source  = "registry.opentofu.org/hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_compute_image" "debian" {
  family  = "debian-13"
  project = "debian-cloud"
}

resource "google_compute_instance" "vm" {
  for_each     = { for vm in var.vms : vm.name => vm }

  name         = each.value.name
  machine_type = each.value.machine_type
  zone         = var.zone

  labels = merge(
    { owner = "lab", purpose = "lab", day = var.day },
    lookup(each.value, "labels", {})
  )

  tags = ["lab-fw"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian.self_link
      size  = each.value.disk_gb
      type  = "pd-standard"
    }
  }

  network_interface {
    network = "default"
    access_config {}  # 分配临时外部 IP
  }

  metadata = lookup(each.value, "startup_script", "") != "" ? {
    startup-script = each.value.startup_script
  } : {}

  scheduling {
    preemptible         = lookup(each.value, "spot", false)
    on_host_maintenance = lookup(each.value, "spot", false) ? "TERMINATE" : "MIGRATE"
    automatic_restart   = lookup(each.value, "spot", false) ? false : true
    provisioning_model  = lookup(each.value, "spot", false) ? "SPOT" : "STANDARD"
  }
}
