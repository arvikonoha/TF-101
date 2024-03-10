# main.tf

variable "nat_ami_id" {}

provider "aws" {
  region = "us-east-1"  # Set your desired AWS region
  profile = "konoha"
}

resource "aws_vpc" "tf_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "TF VPC"
    Environment = "Dev"
  }
}

resource "aws_internet_gateway" "tf_igw" {
  vpc_id = aws_vpc.tf_vpc.id

  tags = {
    Name = "TF_IGW"
  }
}

resource "aws_route_table" "tf_rt" {
  vpc_id = aws_vpc.tf_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tf_igw.id
  }
}

resource "aws_subnet" "tf_public_subnet_1" {
  vpc_id = aws_vpc.tf_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "TF Public subnet 1"
    Environment = "Dev"
  }
}

resource "aws_subnet" "tf_public_subnet_2" {
  vpc_id = aws_vpc.tf_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "TF Public subnet 2"
    Environment = "Dev"
  }
}

resource "aws_route_table_association" "tf_public_subnet_1_association" {
  subnet_id      = aws_subnet.tf_public_subnet_1.id
  route_table_id = aws_route_table.tf_rt.id
}

resource "aws_route_table_association" "tf_public_subnet_2_association" {
  subnet_id      = aws_subnet.tf_public_subnet_2.id
  route_table_id = aws_route_table.tf_rt.id
}

resource "aws_subnet" "tf_private_subnet_1" {
  vpc_id = aws_vpc.tf_vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "TF Private subnet 1"
    Environment = "Dev"
  }
}

resource "aws_subnet" "tf_private_subnet_2" {
  vpc_id = aws_vpc.tf_vpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "TF Private subnet 2"
    Environment = "Dev"
  }
}
resource "aws_security_group" "nat_security_group" {
  name        = "nat_security_group"
  description = "Security group for NAT instance to enable required traffic"
  vpc_id      = aws_vpc.tf_vpc.id

  tags = {
    Name        = "NAT_SG"
    Environment = "Dev"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow incoming HTTP traffic"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow incoming HTTPS traffic"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow incoming SSH traffic"
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow outgoing HTTP traffic"
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow outgoing HTTPS traffic"
  }
}

resource "aws_instance" "tf_nat_instance" {
  key_name = "nat-instance-key"
  ami = var.nat_ami_id
  instance_type = "t2.micro"
  associate_public_ip_address = true
  source_dest_check = false
  subnet_id     = aws_subnet.tf_public_subnet_1.id  # Replace with your tf_public_subnet_1 ID

  vpc_security_group_ids = [aws_security_group.nat_security_group.id]

  tags = {
    Environment = "Dev"
    Purpose = "Nat"
    Project = "konoha"
  }
}

resource "aws_route_table" "tf_private_route_table" {
  vpc_id = aws_vpc.tf_vpc.id

  tags = {
    Name = "TF Private route table"
  }
}

# Route All Traffic to EC2 Instance
resource "aws_route" "route_all_traffic" {
  route_table_id         = aws_route_table.tf_private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_instance.tf_nat_instance.primary_network_interface_id
}

resource "aws_route_table_association" "tf_private_subnet_1_association" {
  subnet_id = aws_subnet.tf_private_subnet_1.id
  route_table_id = aws_route_table.tf_private_route_table.id
}

resource "aws_route_table_association" "tf_private_subnet_2_association" {
  subnet_id = aws_subnet.tf_private_subnet_2.id
  route_table_id = aws_route_table.tf_private_route_table.id
}