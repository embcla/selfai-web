output "server_ip" {
  description = "Public IP address of the server"
  value       = hcloud_server.main.ipv4_address
}

output "ssh_command" {
  description = "SSH command to connect to the server"
  value       = "ssh -i ssh_key root@${hcloud_server.main.ipv4_address}"
}

output "domain" {
  description = "Domain name for the server"
  value       = "selfai.domain"
} 