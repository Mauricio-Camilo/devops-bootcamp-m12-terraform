provider "aws" {
    region = "us-east-1"
}

variable vpc_cidr_block {}
variable private_subnet_cidr_blocks {}
variable public_subnet_cidr_blocks {}

data "aws_availability_zones" "azs" {}

module "myapp-vpc" {
    source = "terraform-aws-modules/vpc/aws"
    version = "5.1.2"

    name = "myapp-vpc"
    cidr = var.vpc_cidr_block
    private_subnets = var.private_subnet_cidr_blocks
    public_subnets = var.public_subnet_cidr_blocks
    azs = data.aws_availability_zones.azs.names

    enable_nat_gateway = true # It is default
    single_nat_gateway = true # All private subnets use this NAT gateway
    enable_dns_hostnames = true # Assign ip addresses for EC2s for example

    tags = {
        "kubernetes.io/cluster/muapp-eks-cluster" = "shared"
    }

    public_subnet_tags = {
        "kubernetes.io/cluster/muapp-eks-cluster" = "shared"
        "kubernetes.io/role/elb" = 1
    }

    private_subnet_tags = {
        "kubernetes.io/cluster/muapp-eks-cluster" = "shared"
        "kubernetes.io/role/internal-elb" = 1
    }
}