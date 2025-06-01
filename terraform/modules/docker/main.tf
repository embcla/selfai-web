resource "null_resource" "docker_setup" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "remote-exec" {
    inline = [
      # Check if Docker and Docker Compose are already installed and working
      <<-EOT
      if command -v docker >/dev/null 2>&1 && \
         command -v docker-compose >/dev/null 2>&1 && \
         docker info >/dev/null 2>&1 && \
         docker-compose version >/dev/null 2>&1; then
        echo "✅ Docker and Docker Compose are already installed and working correctly"
        exit 0
      fi
      EOT
      ,

      # If we get here, Docker needs to be installed or fixed
      # Remove previous docker
      "for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do apt-get remove $pkg; done",

      # Update package lists
      #"apt-get update",

      # Install required packages
      "apt-get install -y ca-certificates curl",

      # Add Docker's official GPG key
      "install -m 0755 -d /etc/apt/keyrings",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc",
      "chmod a+r /etc/apt/keyrings/docker.asc",

      # Add Docker repository
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo \\\"$${UBUNTU_CODENAME:-$${VERSION_CODENAME}}\\\") stable\" | tee /etc/apt/sources.list.d/docker.list > /dev/null",

      # Update package lists again
      "apt-get update",

      # Install Docker
      "apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",

      # Start and enable Docker service
      "systemctl start docker",
      "systemctl enable docker",
      "curl -L \"https://github.com/docker/compose/releases/download/v2.36.2/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",
      "chmod +x /usr/local/bin/docker-compose",

      # Create docker group if it doesn't exist
      "getent group docker || groupadd docker",

      # Verify installation
      <<-EOT
      if ! docker info >/dev/null 2>&1; then
        echo "❌ Docker installation failed"
        exit 1
      fi
      if ! docker-compose version >/dev/null 2>&1; then
        echo "❌ Docker Compose installation failed"
        exit 1
      fi
      echo "✅ Docker and Docker Compose installed successfully"
      EOT
    ]

    connection {
      type        = "ssh"
      user        = var.username
      private_key = var.private_key_path
      host        = var.host
    }
  }
}