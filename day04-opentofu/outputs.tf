output "vm_external_ip" {
  description = "VM 公网 IP"
  value       = google_compute_address.lab_d04_ip.address
}

output "vm_name" {
  description = "VM 名称"
  value       = google_compute_instance.lab_d04_app.name
}

output "whoami_url" {
  description = "whoami 服务 URL"
  value       = "http://${google_compute_address.lab_d04_ip.address}:8080"
}

output "ssh_command" {
  description = "SSH 登录命令"
  value       = "gcloud compute ssh ${google_compute_instance.lab_d04_app.name} --zone=${var.zone}"
}
