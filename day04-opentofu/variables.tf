variable "project_id" {
  description = "GCP 项目 ID"
  type        = string
}

variable "region" {
  description = "GCP 区域"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP 可用区"
  type        = string
  default     = "us-central1-b"
}

variable "machine_type" {
  description = "VM 机型"
  type        = string
  default     = "e2-medium"
}

variable "image_family" {
  description = "VM 操作系统镜像族"
  type        = string
  default     = "debian-13"
}

variable "image_project" {
  description = "VM 镜像所属项目"
  type        = string
  default     = "debian-cloud"
}

variable "network_tag" {
  description = "防火墙目标标签"
  type        = string
  default     = "lab-fw"
}
