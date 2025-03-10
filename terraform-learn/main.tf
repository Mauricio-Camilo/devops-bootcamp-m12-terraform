terraform {
  required_version = ">= 0.12"
  backend "s3" {
    bucket = "mauricio-myapp-tf-s3-bucket"
    key = "myapp/state.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

variable vpc_cidr_block {}

variable subnet_cidr_block {}

variable avail_zone {}

variable env_prefix {}

variable my_ip {}

variable instance_type {}

variable public_key_location {}

resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name: "${var.env_prefix}-vpc"
  }
}

resource "aws_subnet" "myapp-subnet-1" {
  vpc_id = aws_vpc.myapp-vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name: "${var.env_prefix}-subnet-1"
  }
}

resource "aws_internet_gateway" "myappp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id
  tags = {
    Name: "${var.env_prefix}-igw"
  }
}

resource "aws_default_route_table" "main-rtb" {
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myappp-igw.id
  }

  tags = {
    Name = "${var.env_prefix}-main-rtb"
  }
}

resource "aws_default_security_group" "default-sg" {
  vpc_id = aws_vpc.myapp-vpc.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "TCP"
    cidr_blocks = [var.my_ip] # My own IP address
  }

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"] # Anyone can access the app
  }

  egress {
    from_port = 0
    to_port = 0 # Any port is allowed to leave
    protocol = "-1" # Any protocol is accepted
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env_prefix}-default-sg"
  }
}

data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    # values = ["amzn2-ami-kernel-*-x86_64-gp2"] # Image name for any version
    values = ["al2023-ami-2023.*-x86_64"] 
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"] 
  }
}

output "aws_ami_id" {
  value = data.aws_ami.latest-amazon-linux-image.id
}

output "ec2_public_ip" {
  value = aws_instance.myapp-server.public_ip
}

resource "aws_key_pair" "ssh-key" {
  key_name = "server-key"
  public_key =  file(var.public_key_location) # Path of the id_rsa.pub public key
}

resource "aws_instance" "myapp-server" {
  ami = data.aws_ami.latest-amazon-linux-image.id 
  instance_type = var.instance_type # t2.micro

  subnet_id = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [aws_default_security_group.default-sg.id]
  availability_zone = var.avail_zone

  associate_public_ip_address = true # Enable to access via browser
  key_name = aws_key_pair.ssh-key.key_name # Key pair created to ssh into the instance

  user_data = file("entry-script.sh")

  user_data_replace_on_change = true            

  tags = {
    Name = "${var.env_prefix}-server"
  }
}