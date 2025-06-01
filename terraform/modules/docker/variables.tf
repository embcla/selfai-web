variable "username" {
  description = "Username for SSH connection"
  type        = string
}

variable "private_key_path" {
  description = "Path to the private key file for SSH connection"
  type        = string
}

variable "host" {
  description = "Host address for SSH connection"
  type        = string
}