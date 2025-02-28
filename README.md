# Demo Project 1

Automate AWS Infrastructure

## Technologies Used

Terraform, AWS, Docker, Linux, Git

## Project Description

- Create TF project to automate provisioning AWS Infrastructure and its components, such as: VPC, Subnet, Route Table, Internet Gateway, EC2, Security Group
- Configure TF script to automate deploying Docker container to EC2 instance

### Details of project

- Creating VPC and Subnets
Initially, the VPC and subnets were created using the template file provided in the project description. The only parameters used were:
- `cidr_block`, set as a variable
- A tag indicating the environment where these resources are being deployed

To connect Terraform to the AWS account, the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` variables, created in the AWS module, were exported in the terminal. Then, running:

```sh
terraform init
```

This command downloaded the provider files locally. After that, the resources were created by running the command:

```sh
terraform apply
```

It displays the components Terraform will create by default.

After applying Terraform, the AWS console shows the following resources created automatically:
- **Route Table:** Acts as a virtual router for the VPC
- **Network ACL:** Functions as a firewall for the subnets

At this stage, communication is only enabled within the VPC. To allow internet access, the route table needs a connection to an **Internet Gateway**.

- Creating an Internet Gateway and Route Table
A new route table was created with rules for internet connectivity. The internal connection rule to the VPC is automatically created, so only the internet gateway entry was defined.

The route was set with:
- `cidr_block = 0.0.0.0/0` to allow access from all IPs
- The ID of the internet gateway, which is also created via Terraform

The internet gateway requires only the VPC ID to be created.

- Associating Subnets with Route Table
Once these resources are created, subnets need to be associated with the route table that has the internet gateway. This is done using `aws_route_table_association`:

```hcl
resource "aws_route_table_association" "a-rtb-subnet" {
  subnet_id      = aws_subnet.myapp-subnet-1.id
  route_table_id = aws_route_table.myapp-route-table.id
}
```

Alternatively, the default route table can be used for connections:

```hcl
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
```

- Security Groups
Security groups were configured to allow traffic on ports 22 (SSH) and 8080 (Nginx). Two approaches were considered:
1. Creating a new security group
2. Using the default VPC security group

Both options require association with the VPC ID. The following ingress and egress rules were defined:

```hcl
resource "aws_default_security_group" "default-sg" {
  vpc_id = aws_vpc.myapp-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = [var.my_ip] # My own IP address
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"] # Open access to the app
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Any protocol is accepted
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env_prefix}-default-sg"
  }
}
```

- EC2 Image and Instance

  To dynamically select the latest Amazon Linux image, the following data resource was used:

  ```hcl
  data "aws_ami" "latest-amazon-linux-image" {
    most_recent = true
    owners      = ["amazon"]

    filter {
      name   = "name"
      values = ["amzn2-ami-kernel-*-x86_64-gp2"]
    }

    filter {
      name   = "virtualization-type"
      values = ["hvm"]
    }
  }

  output "aws_ami_id" {
    value = data.aws_ami.latest-amazon-linux-image.id
  }
  ```

  - Creating an EC2 Instance

  ```hcl
  resource "aws_instance" "myapp-server" {
    ami               = data.aws_ami.latest-amazon-linux-image.id
    instance_type     = var.instance_type # e.g., t2.micro
    subnet_id         = aws_subnet.myapp-subnet-1.id
    vpc_security_group_ids = [aws_default_security_group.default-sg.id]
    availability_zone = var.avail_zone

    associate_public_ip_address = true
    key_name = "server-key-pair"

    tags = {
      Name = "${var.env_prefix}-server"
    }
  }
  ```

  A new SSH key was created and moved to the `.ssh` folder with proper permissions.

  ## Automating Key Pair Creation
  Instead of manually generating and downloading a new key from AWS, an existing key can be used within Terraform:

  ```hcl
  resource "aws_key_pair" "ssh-key" {
    key_name   = "server-key"
    public_key = file(var.public_key_location)
  }
  ```

  And in the EC2 instance:

  ```hcl
  key_name = aws_key_pair.ssh-key.key_name
  ```

  This process will destroy the previously created instance and launch a new one with the updated key, enabling SSH access without manually referencing the key.

  With this, all the resources are now configured and they will be considered in the terraform apply commnad, with a total of 7 resources:

  ![Diagram](./images/tf-project1-1.png)

  - Running an Entrypoint Script to Start a Docker Container
  Now that the instance is running, it needs to be configured to install Docker and run an application. This is achieved using the `user_data` attribute in EC2, which acts as an entrypoint script:

  ```hcl
  user_data = <<EOF
                  #!/bin/bash
                  sudo yum update -y && sudo yum install -y docker
                  sudo systemctl start docker
                  sudo usermod -aG docker ec2-user
                  docker run -p 8080:80 nginx
              EOF

  user_data_replace_on_change = true
  ```

  Each time the script is modified, Terraform will destroy and recreate the instance, ensuring the updated script runs on launch.

  Once the configuration is complete, the Nginx server can be accessed via the public IP on port 8080.

  ## Extracting Shell Script
  For larger scripts, an external file can be referenced using `file()`, similar to the SSH key setup.

  To check all resources created by Terraform in this project, run:

  ```sh
  terraform state list
  ```

  ![Diagram](./images/tf-project1-2.png)


# Demo Project 2

Modularize Project

## Technologies Used

Terraform, AWS, Docker, Linux, Git

## Project Description

- Divide Terraform resources into reusable modules

### Details of project

  In this project, a Fargate profile was created to enable a serverless mode, meaning that no instances will be created in my account; instead, resources are managed by AWS's managed account.

- Create IAM Role for Fargate

# Demo Project 3

Terraform & AWS EKS

## Technologies Used

Terraform, AWS EKS, Docker, Linux, Git

## Project Description

- Automate provisioning EKS cluster with Terraform

### Details of project  


# Demo Project 4

Configure a Shared Remote State

## Technologies Used

Terraform, AWS S3

## Project Description

- Configure Amazon S3 as remote storage for Terraform state

### Details of project   

- Install kubectl on the Jenkins Server

# Demo Project 5

Complete CI/CD with Terraform

## Technologies Used

Terraform, Jenkins, Docker, AWS, Git, Java, Maven, Linux, Docker Hub

## Project Description

Integrate provisioning stage into complete CI/CD Pipeline to automate provisioning server instead of
deploying to an existing server

- Create SSH Key Pair
- Install Terraform inside Jenkins container
- Add Terraform configuration to application’s git repository
- Adjust Jenkinsfile to add “provision” step to the CI/CD pipeline that provisions EC2 instance
- So the complete CI/CD project we build has the following configuration:
    a. CI step: Build artifact for Java Maven application
    b. CI step: Build and push Docker image to Docker Hub
    c. CD step: Automatically provision EC2 instance using TF
    d. CD step: Deploy new application version on the provisioned EC2 instance with Docker Compose

### Details of project   

- Install kubectl on Jenkins Server

  The first step is to log in to the cloud server instance running Jenkins and access the container running Jenkins. The commands used to install kubectl are listed below:

 