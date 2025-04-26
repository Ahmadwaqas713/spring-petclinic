# Get list of available AZs automatically
data "aws_availability_zones" "available" {}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Create a Subnet in the first available AZ
resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]  # <- Pick the first available zone
  map_public_ip_on_launch = true  # Ensure instances get public IP
}

# Create a Security Group to allow SSH and HTTP
resource "aws_security_group" "allow_web_ssh" {
  name        = "allow_web_ssh"
  description = "Allow SSH and HTTP inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create 3 EC2 instances
resource "aws_instance" "server" {
  count                   = 3
  ami                     = "ami-0a7cf821b91bcccbc" # Ubuntu 22.04 LTS (ap-south-1 Mumbai)
  instance_type           = "t2.micro"
  subnet_id               = aws_subnet.main.id
  vpc_security_group_ids  = [aws_security_group.allow_web_ssh.id]
  key_name                = var.key_name
  associate_public_ip_address = true  # <- Assign public IPs directly

  tags = {
    Name = "server-${count.index + 1}"
  }
}

# Output public IPs
output "public_ips" {
  value = aws_instance.server[*].public_ip
}

