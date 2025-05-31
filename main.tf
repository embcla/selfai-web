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

# Generate SSH key
resource "tls_private_key" "ssh_key" {
  algorithm = "ED25519"
}

# Save private key locally
resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_openssh
  filename        = "${path.module}/selfai_ssh_key"
  file_permission = "0600"
}

# Save public key locally
resource "local_file" "public_key" {
  content         = tls_private_key.ssh_key.public_key_openssh
  filename        = "${path.module}/selfai_ssh_key.pub"
  file_permission = "0644"
}

# Upload SSH key to Hetzner
resource "hcloud_ssh_key" "default" {
  name       = "terraform-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# Create Hetzner Cloud frontend server
resource "hcloud_server" "frontend" {
  name        = "frontend"
  image       = var.frontend_image
  server_type = var.frontend_type
  location    = var.frontend_location
  ssh_keys    = [hcloud_ssh_key.default.id]
  labels = {
    group       = "selfai"
    role        = "frontend"
    environment = "production"
    managed-by  = "terraform"
  }

  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "apt-get install -y docker.io docker-compose",
      "systemctl enable docker",
      "systemctl start docker"
    ]

    connection {
      type        = "ssh"
      user        = "root"
      private_key = tls_private_key.ssh_key.private_key_openssh
      host        = self.ipv4_address
    }
  }
}

# Create Hetzner Cloud vector db server
resource "hcloud_server" "vectordb" {
  name        = "vectordb"
  image       = var.vectordb_image
  server_type = var.vectordb_type
  location    = var.vectordb_location
  ssh_keys    = [hcloud_ssh_key.default.id]
  labels = {
    group       = "selfai"
    role        = "vectordb"
    environment = "production"
    managed-by  = "terraform"
  }

  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "apt-get install -y docker.io docker-compose",
      "systemctl enable docker",
      "systemctl start docker"
    ]

    connection {
      type        = "ssh"
      user        = "root"
      private_key = tls_private_key.ssh_key.private_key_openssh
      host        = self.ipv4_address
    }
  }
}

# Create DNS record
resource "cloudflare_record" "dns" {
  zone_id = var.cloudflare_zone_id
  name    = "selfai"
  value   = hcloud_server.frontend.ipv4_address
  type    = "A"
  ttl     = 1
  proxied = true
} 