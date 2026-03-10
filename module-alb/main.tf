provider "aws" {
  region = "us-east-1"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

module "security_group" {
  source = "./modules/security_group"
  vpc_id = data.aws_vpc.default.id
}

module "alb" {
  source    = "./modules/alb"
  vpc_id    = data.aws_vpc.default.id
  subnets   = data.aws_subnets.default.ids
  alb_sg_id = module.security_group.alb_sg_id
}

module "autoscaling" {
  source           = "./modules/autoscaling"
  ami_id           = var.ami_id
  instance_type    = var.instance_type
  instance_sg_id   = module.security_group.instance_sg_id
  target_group_arn = module.alb.target_group_arn
  subnets          = data.aws_subnets.default.ids
}