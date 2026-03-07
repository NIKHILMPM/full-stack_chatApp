########################################
# Provider
########################################

provider "aws" {
  region = var.region
}

########################################
# Fetch Default VPC
########################################

data "aws_vpc" "default" {
  default = true
}

########################################
# Fetch Default Security Group
########################################

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = data.aws_vpc.default.id
}

########################################
# EC2 Instance
########################################

resource "aws_instance" "devops_server" {
  ami                         = var.ami_id
  instance_type               = "t3.large"
  key_name                    = var.key_name
  vpc_security_group_ids      = [data.aws_security_group.default.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "devops-kind-server"
  }
}

########################################
# Output
########################################

output "public_ip" {
  value = aws_instance.devops_server.public_ip
}
