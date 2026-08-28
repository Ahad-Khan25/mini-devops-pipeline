# Find the latest official Ubuntu 22.04 AMI, rather than hardcoding an AMI ID
# (AMI IDs are region-specific and change over time — hardcoding one is a
# classic Terraform mistake that breaks the moment you change region)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# Reuse the SSH key you already generated for GitHub
resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-key"
  public_key = file("~/.ssh/id_ed25519.pub")
}

resource "aws_security_group" "app_sg" {
  name        = "${var.project_name}-sg"
  description = "Allow SSH, HTTP, and app port"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP (Nginx reverse proxy)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Flask app (direct, for testing before Nginx is set up)"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg"
  }
}

resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  # Bootstraps Docker on first boot, so the instance is ready
  # to run containers the moment it's up
  user_data = <<-EOF2
    #!/bin/bash
    apt-get update -y
    apt-get install -y docker.io
    systemctl enable docker
    systemctl start docker
    usermod -aG docker ubuntu
  EOF2

  tags = {
    Name = var.project_name
  }
}
