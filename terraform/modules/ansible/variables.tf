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

variable "ssh_keys" {
  description = "List of SSH key IDs to add to the server"
  type        = list(string)
}

variable "ansible_operator_public_key" {
  description = "Public key for ansible-operator user"
  type        = string
}