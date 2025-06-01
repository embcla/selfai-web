variable "server_name" {
  description = "Name of the server"
  type        = string
}

variable "server_image" {
  description = "Server image to use"
  type        = string
  default     = "ubuntu-24.04" #"docker-ce"
}

variable "server_type" {
  description = "Server type/size"
  type        = string
  default     = "cx22"
}

variable "server_location" {
  description = "Server location/datacenter"
  type        = string
  default     = "nbg1"
}

variable "server_role" {
  description = "Role of the server (e.g., frontend, vectordb)"
  type        = string
}

variable "root_private_key" {
  description = "Private key for root SSH access"
  type        = string
  sensitive   = true
}

variable "root_ssh_key_id" {
  description = "ID of the root SSH key in Hetzner Cloud"
  type        = string
}