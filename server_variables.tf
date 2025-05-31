variable "frontend_image" {
  description = "Server image to use"
  type        = string
  default     = "docker-ce" #"ubuntu-24.04"
}

variable "frontend_type" {
  description = "Server type/size"
  type        = string
  default     = "cx22"
}

variable "frontend_location" {
  description = "Server location/datacenter"
  type        = string
  default     = "nbg1"
}

variable "vectordb_image" {
  description = "Server image to use"
  type        = string
  default     = "docker-ce" #"ubuntu-24.04"
}

variable "vectordb_type" {
  description = "Server type/size"
  type        = string
  default     = "ccx13"
}

variable "vectordb_location" {
  description = "Server location/datacenter"
  type        = string
  default     = "nbg1"
}
