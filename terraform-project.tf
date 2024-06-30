
#Providing details to the terraform that which is the server, regions and what the secrets
provider "aws" {
  region = "us-east-1"
  access_key = "Access-Key"
  secret_key = "Secret-Key"
}

# Create VPC
resource "aws_vpc" "testing" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "testing"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.testing.id

  tags = {
    Name = "testing"
  }
}

# Create Route Table
resource "aws_route_table" "testing" {
  vpc_id = aws_vpc.testing.id

  route {
    cidr_block = "0.0.0.0/0"  # Allow all IPv4 traffic
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "testing"
  }
}

# Create Subnet
resource "aws_subnet" "testing" {
  vpc_id            = aws_vpc.testing.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"  # Optional

  tags = {
    Name = "testing"
  }
}

# Associate Subnet with Route Table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.testing.id
  route_table_id = aws_route_table.testing.id
}

# Create Security Group
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.testing.id

  tags = {
    Name = "allow_web"
  }
}

# Security Group Ingress Rules
resource "aws_security_group_rule" "allow_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_web.id
  description       = "Allow HTTP traffic"
}

resource "aws_security_group_rule" "allow_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_web.id
  description       = "Allow HTTPS traffic"
}

resource "aws_security_group_rule" "allow_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_web.id
  description       = "Allow SSH traffic"
}

# Security Group Egress Rules
resource "aws_security_group_rule" "allow_all_egress_ipv4" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_web.id
  description       = "Allow all outbound IPv4 traffic"
}

resource "aws_security_group_rule" "allow_all_egress_ipv6" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.allow_web.id
  description       = "Allow all outbound IPv6 traffic"
}

# Create Network Interface
resource "aws_network_interface" "web_server_nic" {
  subnet_id       = aws_subnet.testing.id
  private_ips     = ["10.0.1.10"]
  security_groups = [aws_security_group.allow_web.id]

  tags = {
    Name = "web_server_nic"
  }
}

# Create Elastic IP
resource "aws_eip" "one" {
  vpc                      = true
  network_interface        = aws_network_interface.web_server_nic.id
  associate_with_private_ip = "10.0.1.10"
  depends_on               = [aws_internet_gateway.gw]
}

# Create EC2 Instance and install Apache
resource "aws_instance" "web_server_instance" {
  ami               = "ami-08a0d1e16fc3f61ea"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1a"
  key_name          = "server-access"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.web_server_nic.id
  }

  tags = {
    Name = "web_server_instance"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt upgrade -y
              sudo apt install -y apache2
              sudo systemctl start apache2
              sudo systemctl enable apache2
              echo 'Testing the first web server' < sudo tee /var/www/html/index.html
              EOF
}
