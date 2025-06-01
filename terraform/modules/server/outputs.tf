output "server_id" {
  description = "ID of the created server"
  value       = hcloud_server.server.id
}

output "server_ipv4" {
  description = "IPv4 address of the server"
  value       = hcloud_server.server.ipv4_address
}

output "server_name" {
  description = "Name of the server"
  value       = hcloud_server.server.name
}