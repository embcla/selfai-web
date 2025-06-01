resource "null_resource" "ansible_setup" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "apt-get install -y python3 python3-pip python3-venv python3-full",

      # Create ansible-operator user
      "useradd -m -s /bin/bash ansible-operator || true",

      # Add user to docker group
      "usermod -aG docker ansible-operator",

      # Create .ssh directory for the new user
      "mkdir -p /home/ansible-operator/.ssh",

      # Set correct permissions
      "chmod 700 /home/ansible-operator/.ssh",

      # Add the public key
      "echo '${var.ansible_operator_public_key}' > /home/ansible-operator/.ssh/authorized_keys",

      # Set correct ownership
      "chown -R ansible-operator:ansible-operator /home/ansible-operator/.ssh",

      # Set correct permissions for authorized_keys
      "chmod 600 /home/ansible-operator/.ssh/authorized_keys",

      # Configure SSH for local access
      "sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config",
      "sed -i 's/^#PermitUserEnvironment.*/PermitUserEnvironment yes/' /etc/ssh/sshd_config",
      "systemctl restart ssh",

      # Create Python virtual environment for ansible-operator
      "sudo -u ansible-operator bash -c 'python3 -m venv /home/ansible-operator/venv'",

      # Install required Python packages in the virtual environment
      "sudo -u ansible-operator bash -c '/home/ansible-operator/venv/bin/pip install --upgrade pip'",
      "sudo -u ansible-operator bash -c '/home/ansible-operator/venv/bin/pip install six'",

      # Add virtual environment activation to .bashrc
      "echo 'source /home/ansible-operator/venv/bin/activate' >> /home/ansible-operator/.bashrc",

      # Ensure proper ownership of the virtual environment
      "chown -R ansible-operator:ansible-operator /home/ansible-operator/venv",

      # Create verification script
      <<-EOT
      cat > /tmp/verify_setup.sh <<'EOF'
      #!/bin/bash
      set -e

      echo "Starting verification process..."

      # Verify Python access
      echo "Verifying Python access..."
      if ! sudo -u ansible-operator bash -c 'python3 --version' > /dev/null 2>&1; then
        echo "❌ Python system access failed"
        exit 1
      fi
      if ! sudo -u ansible-operator bash -c '/home/ansible-operator/venv/bin/python --version' > /dev/null 2>&1; then
        echo "❌ Python virtual environment access failed"
        exit 1
      fi
      echo "✅ Python access verified"

      # Verify Docker access
      echo "Verifying Docker access..."
      if ! sudo -u ansible-operator bash -c 'docker ps' > /dev/null 2>&1; then
        echo "❌ Docker basic access failed"
        exit 1
      fi
      if ! sudo -u ansible-operator bash -c 'docker info' > /dev/null 2>&1; then
        echo "❌ Docker full access failed"
        exit 1
      fi
      echo "✅ Docker access verified"

      # Verify SSH key setup
      echo "Verifying SSH key setup..."
      if [ ! -f /home/ansible-operator/.ssh/authorized_keys ]; then
        echo "❌ authorized_keys file not found"
        exit 1
      fi
      if [ "$(stat -c %a /home/ansible-operator/.ssh/authorized_keys)" != "600" ]; then
        echo "❌ authorized_keys has incorrect permissions"
        exit 1
      fi
      if [ "$(stat -c %U:%G /home/ansible-operator/.ssh/authorized_keys)" != "ansible-operator:ansible-operator" ]; then
        echo "❌ authorized_keys has incorrect ownership"
        exit 1
      fi
      if ! grep -q "${var.ansible_operator_public_key}" /home/ansible-operator/.ssh/authorized_keys; then
        echo "❌ authorized_keys does not contain the expected public key"
        exit 1
      fi
      echo "✅ SSH key setup verified"

      echo "All verifications passed successfully! ✨"
      EOF

      chmod +x /tmp/verify_setup.sh
      /tmp/verify_setup.sh
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