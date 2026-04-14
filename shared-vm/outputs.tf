output "vms" {
  description = "所有 VM 的名称和 IP"
  value = {
    for name, vm in google_compute_instance.vm :
    name => {
      external_ip = vm.network_interface[0].access_config[0].nat_ip
      internal_ip = vm.network_interface[0].network_ip
    }
  }
}
