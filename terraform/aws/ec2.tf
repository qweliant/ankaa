# Fetch the latest Amazon Linux 2023 AMI (Same as before)
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-arm64"]
  }
}

# Define the Server
resource "aws_instance" "ankaa_app_server" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t4g.small"

  # Use the Output from the VPC Module
  # We are putting this in the PRIVATE subnet so it has a no path to the internet
  subnet_id = module.vpc.private_subnets[0]
  # Use the Output from the App Security Group Module
  vpc_security_group_ids = [module.app_sg.security_group_id]


  # This connects the "Identity" we made earlier (IAM Role) to this specific server
  iam_instance_profile = aws_iam_instance_profile.ankaa_app_profile.name

  associate_public_ip_address = false

  tags = {
    Name        = "Ankaa-App-Server"
    Environment = "Production"
    Arch        = "ARM64"
  }

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello Ankaa! Setting up the server..."
              dnf update -y
              dnf install -y docker
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user
              EOF
}
