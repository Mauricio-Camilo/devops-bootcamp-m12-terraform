resource "aws_default_security_group" "default-sg" {
  vpc_id = var.vpc_id

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
    values = [var.image_name] # Image name for any version

  }
  filter {
    name = "virtualization-type"
    values = ["hvm"] 
  }
}

resource "aws_key_pair" "ssh-key" {
  key_name = "server-key"
  public_key =  file(var.public_key_location) # Path of the id_rsa.pub public key
}

resource "aws_instance" "myapp-server" {
  ami = data.aws_ami.latest-amazon-linux-image.id 
  instance_type = var.instance_type # t2.micro

  subnet_id = var.subnet_id
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
