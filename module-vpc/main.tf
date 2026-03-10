provider "aws" {
  region = var.aws_region
}

module "vpc_network" {  ##create a module for vpc and call it here

  source = "./modules/vpc"

  vpc_cidr = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones = var.availability_zones
}