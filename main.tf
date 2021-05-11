locals {
  name_prefix = var.name_prefix
  default_tags = {
    Terraform = "true"
    Owner     = var.owner
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.0.0"

  name = "${local.name_prefix}-vpc"
  cidr = "10.128.0.0/16"

  azs             = [data.aws_availability_zones.available.names[0]]
  private_subnets = ["10.128.20.0/24"]
  public_subnets  = ["10.128.10.0/24"]

  enable_nat_gateway = true

  tags = local.default_tags
}

module "bigip_1arm_autoscale" {
  source = "./modules/bigip-1arm-autoscale"

  key_pair    = var.key_pair
  name_prefix = local.name_prefix

  vpc_id             = module.vpc.vpc_id
  external_subnet_id = module.vpc.public_subnets[0]
  internal_subnet_id = module.vpc.private_subnets[0]

  default_tags = local.default_tags
}

module "nginx" {
  source = "./modules/nginx"

  key_pair    = var.key_pair
  name_prefix = local.name_prefix

  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnets[0]

  default_tags = local.default_tags
}
