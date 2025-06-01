resource "hcloud_server" "server" {
  name        = var.server_name
  image       = var.server_image
  server_type = var.server_type
  location    = var.server_location
  ssh_keys    = [var.root_ssh_key_id]

  labels = {
    group       = "selfai"
    role        = var.server_role
    environment = "production"
    managed-by  = "terraform"
  }

  provisioner "remote-exec" {
    inline = [
      "apt update -y",
      "apt upgrade -y",
      "reboot"
    ]

    connection {
      type        = "ssh"
      user        = "root"
      private_key = var.root_private_key
      host        = self.ipv4_address
    }
  }
}