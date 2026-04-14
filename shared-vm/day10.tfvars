day = "d10"

vms = [
  {
    name         = "lab-swarm-manager"
    machine_type = "e2-medium"
    disk_gb      = 20
    spot         = false
  },
  {
    name         = "lab-swarm-worker-1"
    machine_type = "e2-medium"
    disk_gb      = 20
    spot         = true
  },
  {
    name         = "lab-swarm-worker-2"
    machine_type = "e2-medium"
    disk_gb      = 20
    spot         = true
  },
  {
    name         = "lab-swarm-worker-3"
    machine_type = "e2-medium"
    disk_gb      = 20
    spot         = true
  },
  {
    name         = "lab-swarm-worker-4"
    machine_type = "e2-medium"
    disk_gb      = 20
    spot         = true
  }
]
