variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "zone" {
  type    = string
  default = "us-central1-b"
}

variable "day" {
  description = "实验天标签，如 d07"
  type        = string
}

variable "vms" {
  description = "要创建的 VM 列表"
  type = list(object({
    name           = string
    machine_type   = string
    disk_gb        = number
    spot           = optional(bool, false)
    startup_script = optional(string, "")
    labels         = optional(map(string), {})
  }))
}
