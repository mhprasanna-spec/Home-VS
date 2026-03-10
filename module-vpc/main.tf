provider "aws" {
    region =var.aws_region
  
}

module vpc_network {

source = "./modules/vpc"

aws_region = var.aws_region
vpc_cidr = var.vpc_cidr
public_subnet_cidrs = var.public_subnet_cidrs
private_subnet_cidrs = var.private_subnet_cidrs
availability_zones = var.availability_zones

}
