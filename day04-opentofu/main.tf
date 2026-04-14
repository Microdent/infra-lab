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

# ---------- 静态外部 IP ----------
resource "google_compute_address" "lab_d04_ip" {
  name   = "lab-d04-ip"
  region = var.region
}

# ---------- VM 实例 ----------
resource "google_compute_instance" "lab_d04_app" {
  name         = "lab-d04-app"
  machine_type = var.machine_type
  zone         = var.zone

  labels = {
    owner   = "lab"
    purpose = "lab"
    day     = "d04"
  }

  tags = [var.network_tag]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian.self_link
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.lab_d04_ip.address
    }
  }

  metadata = {
    startup-script = <<-SCRIPT
      #!/bin/bash
      set -e
      apt-get update -q
      apt-get install -y -q ca-certificates curl gnupg
      install -m 0755 -d /etc/apt/keyrings
      curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
      chmod a+r /etc/apt/keyrings/docker.gpg
      echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
        > /etc/apt/sources.list.d/docker.list
      apt-get update -q
      apt-get install -y -q docker-ce docker-ce-cli containerd.io docker-compose-plugin
      docker run -d --name whoami --restart unless-stopped -p 8080:80 traefik/whoami
      echo "STARTUP COMPLETE" > /dev/console
    SCRIPT
  }
}

# ---------- 查找最新 Debian 13 镜像 ----------
data "google_compute_image" "debian" {
  family  = var.image_family
  project = var.image_project
}
