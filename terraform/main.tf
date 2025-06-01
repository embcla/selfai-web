terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Generate SSH keys
resource "tls_private_key" "root_key" {
  algorithm = "ED25519"
}

resource "tls_private_key" "ansible_operator_key" {
  algorithm = "ED25519"
}

# Save SSH keys locally
resource "local_file" "root_private_key" {
  content         = tls_private_key.root_key.private_key_openssh
  filename        = "${path.module}/selfai_ssh_key"
  file_permission = "0600"
}

resource "local_file" "root_public_key" {
  content         = tls_private_key.root_key.public_key_openssh
  filename        = "${path.module}/selfai_ssh_key.pub"
  file_permission = "0644"
}

resource "local_file" "ansible_operator_private_key" {
  content         = tls_private_key.ansible_operator_key.private_key_openssh
  filename        = "${path.module}/key-ansible-operator-ed25519"
  file_permission = "0600"
}

resource "local_file" "ansible_operator_public_key" {
  content         = tls_private_key.ansible_operator_key.public_key_openssh
  filename        = "${path.module}/key-ansible-operator-ed25519.pub"
  file_permission = "0644"
}

# Upload SSH keys to Hetzner
resource "hcloud_ssh_key" "root_key" {
  name       = "root-key"
  public_key = tls_private_key.root_key.public_key_openssh
}

resource "hcloud_ssh_key" "ansible_operator_key" {
  name       = "ansible-operator-key"
  public_key = tls_private_key.ansible_operator_key.public_key_openssh
}

# Create servers using the module
module "frontend" {
  source = "./modules/server"

  server_name              = "frontend"
  server_role              = "frontend"
  root_ssh_key_id          = hcloud_ssh_key.root_key.id
  root_private_key         = tls_private_key.root_key.private_key_openssh
}

#module "vectordb" {
#  source = "./modules/server"
#
#  server_name             = "vectordb"
#  server_type             = "ccx13"
#  server_location         = var.vectordb_location
#  server_role             = "vectordb"
#  root_ssh_key_id         = hcloud_ssh_key.root_key.id
#  root_private_key        = tls_private_key.root_key.private_key_openssh
#}

#provision server with docker using the module
module "provision_docker_on_frontend" {
    source                 = "./modules/docker"

    username               = "root"
    private_key_path       = tls_private_key.root_key.private_key_openssh
    host                   = module.frontend.server_ipv4
}

#provision server with ansible using the module
module "provision_ansible_on_frontend" {
    source                 = "./modules/ansible"

    username               = "root"
    ssh_keys               = [hcloud_ssh_key.root_key.id, hcloud_ssh_key.ansible_operator_key.id]
    private_key_path       = tls_private_key.root_key.private_key_openssh
    host                   = module.frontend.server_ipv4
    ansible_operator_public_key = tls_private_key.ansible_operator_key.public_key_openssh

    depends_on = [module.provision_docker_on_frontend]
}

## Create DNS record
#resource "cloudflare_record" "dns" {
#  zone_id = var.cloudflare_zone_id
#  name    = "selfai"
#  value   = module.frontend.server_ipv4
#  type    = "A"
#  ttl     = 1
#  proxied = true
#}

# Outputs
#output "frontend_ip" {
#  description = "Public IP address of the frontend server"
#  value       = module.frontend.server_ipv4
#}
#
#output "vectordb_ip" {
#  description = "Public IP address of the vector db server"
#  value       = module.vectordb.server_ipv4
#}

output "ssh_command_frontend" {
  description = "SSH command to connect to the frontend server"
  value       = "ssh -i <key> root@${module.frontend.server_ipv4}"
}

#output "ssh_command_vectordb" {
#  description = "SSH command to connect to the frontend server"
#  value       = "ssh -i <key> root@${module.vectordb.server_ipv4}"
#}

#output "domain" {
#  description = "Domain name for the server"
#  value       = "selfai.domain"
#}

output "root_ssh_key_path" {
  description = "Path to the root SSH private key"
  value       = local_file.root_private_key.filename
}

output "ansible_operator_ssh_key_path" {
  description = "Path to the ansible-operator SSH private key"
  value       = local_file.ansible_operator_private_key.filename
}