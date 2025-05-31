variable "server_image" {
  description = "Server image to use"
  type        = string
  default     = "ubuntu-22.04"
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