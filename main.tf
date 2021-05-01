locals {
  name_prefix = var.name_prefix
  owner       = var.owner
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
  public_subnets  = ["10.128.10.0/24", "10.128.30.0/24"]

  enable_nat_gateway = true

  tags = {
    Terraform = "true"
    Owner     = local.owner
  }
}

module "nlb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 5.0"

  name = "${local.name_prefix}-external-nlb"

  load_balancer_type = "network"

  vpc_id  = module.vpc.vpc_id
  subnets = [module.vpc.public_subnets[0]]

  tags = {
    Terraform = "true"
    Owner     = local.owner
  }
}

module "bigip-3arm-autoscale" {
  source = "./modules/bigip-3arm-autoscale"

  key_pair    = var.key_pair
  name_prefix = "${local.name_prefix}"

  vpc_id               = module.vpc.vpc_id
  management_subnet_id = module.vpc.public_subnets[1]
  external_subnet_id   = module.vpc.public_subnets[0]
  internal_subnet_id   = module.vpc.private_subnets[0]

  provisioned_modules = ["\"ltm\": \"nominal\""]

  default_tags = {
    Terraform     = "true"
    Owner         = local.owner
  }
}
