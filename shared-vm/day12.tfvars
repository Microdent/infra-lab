day = "d12"

vms = [
  {
    name         = "lab-k3s-server-1"
    machine_type = "e2-standard-2"
    disk_gb      = 20
    spot         = false
  },
  {
    name         = "lab-k3s-server-2"
    machine_type = "e2-medium"
    disk_gb      = 20
    spot         = false
  },
  {
    name         = "lab-k3s-agent-1"
    machine_type = "e2-medium"
    disk_gb      = 20
    spot         = true
  },
  {
    name         = "lab-k3s-agent-2"
    machine_type = "e2-medium"
    disk_gb      = 20
    spot         = true
  },
  {
    name         = "lab-k3s-agent-3"
    machine_type = "e2-medium"
    disk_gb      = 20
    spot         = true
  }
]
